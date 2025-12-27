#!/usr/bin/env python3
"""
BakkesMod plugin updater.
Fetches all plugins from bakkesplugins.com and calculates their hashes.

Usage:
    nix run .#update                    # Update all plugins
    nix run .#update -- --no-hash       # Update metadata only (fast)
    nix run .#update -- --plugin 30     # Update specific plugin by ID
"""

import argparse
import json
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

API_BASE = "https://bakkesplugins.com/api"

def get_data_file() -> Path:
    """Get the data file path from env or default."""
    import os
    if "BAKKESMOD_DATA_DIR" in os.environ:
        return Path(os.environ["BAKKESMOD_DATA_DIR"]) / "plugins.json"
    # Default: relative to current working directory
    return Path.cwd() / "data" / "plugins.json"


def fetch_json(url: str) -> dict:
    """Fetch JSON from URL."""
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.loads(response.read().decode())


def fetch_all_plugins() -> list[dict]:
    """Fetch all plugins from the API (paginated)."""
    plugins = []
    page = 1

    print("Fetching plugin list from bakkesplugins.com...")

    while True:
        print(f"  Page {page}...", end=" ", flush=True)
        data = fetch_json(f"{API_BASE}/plugins?page={page}&pageSize=50")
        items = data.get("items", [])
        plugins.extend(items)
        print(f"({len(items)} plugins)")

        if page >= data.get("totalPages", 1):
            break
        page += 1

    print(f"Found {len(plugins)} plugins total")
    return plugins


def get_plugin_download_url(plugin_id: int) -> str | None:
    """Get the CDN download URL for a plugin."""
    try:
        versions = fetch_json(f"{API_BASE}/plugins/{plugin_id}/versions")
        if versions and len(versions) > 0:
            return versions[0].get("binaryDownloadUrl")
    except Exception as e:
        print(f"    Warning: Could not fetch versions for plugin {plugin_id}: {e}")
    return None


def calculate_hash(url: str) -> str | None:
    """Download file and calculate its SHA256 hash using nix-prefetch-url."""
    try:
        # Use nix-prefetch-url to download and hash in one step
        # Use --name to avoid issues with special characters in URLs
        result = subprocess.run(
            ["nix-prefetch-url", "--type", "sha256", "--name", "plugin.zip", url],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode == 0:
            base32_hash = result.stdout.strip()
            # Convert to SRI format
            convert = subprocess.run(
                ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", base32_hash],
                capture_output=True,
                text=True,
            )
            if convert.returncode == 0:
                return convert.stdout.strip()
            # Fallback: return base32 format
            return f"sha256:{base32_hash}"
    except subprocess.TimeoutExpired:
        print(f"    Timeout downloading {url}")
    except Exception as e:
        print(f"    Error hashing {url}: {e}")
    return None


def process_plugin(plugin: dict, fetch_hash: bool, existing_hashes: dict) -> dict:
    """Process a single plugin, optionally fetching its hash."""
    plugin_id = plugin["id"]
    name = plugin["name"]
    version = plugin.get("versionString", "unknown")

    # Check if we already have data for this version
    existing = existing_hashes.get(plugin_id, {})
    if existing.get("version") == version and existing.get("hash") and existing.get("url"):
        return {
            "id": plugin_id,
            "name": name,
            "version": version,
            "description": plugin.get("shortDescription", ""),
            "url": existing["url"],
            "hash": existing["hash"],
        }

    result = {
        "id": plugin_id,
        "name": name,
        "version": version,
        "description": plugin.get("shortDescription", ""),
        "url": "",
        "hash": "",
    }

    if fetch_hash:
        print(f"  [{plugin_id}] {name} v{version}")
        download_url = get_plugin_download_url(plugin_id)
        if download_url:
            result["url"] = download_url
            hash_value = calculate_hash(download_url)
            if hash_value:
                result["hash"] = hash_value
                print(f"    ✓ {hash_value[:30]}...")
            else:
                print("    ✗ Failed to calculate hash")
        else:
            print("    ✗ No download URL")

    return result


def load_existing_plugins(data_file: Path) -> dict:
    """Load existing plugins.json and return a dict of id -> {version, hash, url}."""
    if not data_file.exists():
        return {}

    try:
        with open(data_file) as f:
            plugins = json.load(f)
        return {
            p["id"]: {
                "version": p["version"],
                "hash": p.get("hash", ""),
                "url": p.get("url", ""),
            }
            for p in plugins
        }
    except Exception:
        return {}


def main():
    parser = argparse.ArgumentParser(description="Update BakkesMod plugins data")
    parser.add_argument(
        "--no-hash",
        action="store_true",
        help="Skip hash calculation (fast metadata-only update)",
    )
    parser.add_argument(
        "--plugin",
        type=int,
        help="Update only a specific plugin by ID",
    )
    parser.add_argument(
        "--parallel",
        type=int,
        default=4,
        help="Number of parallel hash calculations (default: 4)",
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        help="Directory containing plugins.json (default: ./data)",
    )
    args = parser.parse_args()

    # Get data file location
    if args.data_dir:
        data_file = args.data_dir / "plugins.json"
    else:
        data_file = get_data_file()
    print(f"Data file: {data_file}")

    # Load existing data to preserve hashes
    existing_hashes = load_existing_plugins(data_file)
    print(f"Loaded {len(existing_hashes)} existing plugins")

    # Fetch plugins
    all_plugins = fetch_all_plugins()

    # Filter if specific plugin requested
    if args.plugin:
        all_plugins = [p for p in all_plugins if p["id"] == args.plugin]
        if not all_plugins:
            print(f"Plugin {args.plugin} not found")
            sys.exit(1)

    # Process plugins
    fetch_hash = not args.no_hash
    results = []

    if fetch_hash and len(all_plugins) > 1:
        print(f"\nCalculating hashes (parallel={args.parallel})...")
        with ThreadPoolExecutor(max_workers=args.parallel) as executor:
            futures = {
                executor.submit(process_plugin, p, True, existing_hashes): p
                for p in all_plugins
            }
            for future in as_completed(futures):
                results.append(future.result())
    else:
        if fetch_hash:
            print("\nCalculating hashes...")
        for plugin in all_plugins:
            results.append(process_plugin(plugin, fetch_hash, existing_hashes))

    # Sort by ID for consistent output
    results.sort(key=lambda x: x["id"])

    # If updating a single plugin, merge with existing data
    if args.plugin and data_file.exists():
        with open(data_file) as f:
            existing = json.load(f)
        # Replace the updated plugin
        existing = [p for p in existing if p["id"] != args.plugin]
        existing.extend(results)
        existing.sort(key=lambda x: x["id"])
        results = existing

    # Write output
    data_file.parent.mkdir(parents=True, exist_ok=True)
    with open(data_file, "w") as f:
        json.dump(results, f, indent=2)

    # Summary
    with_hash = sum(1 for p in results if p["hash"])
    print(f"\n✓ Wrote {len(results)} plugins to {data_file}")
    print(f"  {with_hash} with hashes, {len(results) - with_hash} without")


if __name__ == "__main__":
    main()
