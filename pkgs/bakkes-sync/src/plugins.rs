use std::collections::HashSet;
use std::fs;
use std::io::Write;
use std::path::Path;
use std::time::Instant;

use crate::log;
use crate::manifest::Manifest;
use crate::path_safety;

pub fn sync(manifest: &Manifest, bakkes_data: &Path) -> Result<(), String> {
    let plugins_dir = bakkes_data.join("plugins");
    fs::create_dir_all(&plugins_dir)
        .map_err(|e| format!("Failed to create plugins dir: {e}"))?;
    fs::create_dir_all(plugins_dir.join("settings"))
        .map_err(|e| format!("Failed to create plugins/settings dir: {e}"))?;
    fs::create_dir_all(bakkes_data.join("data"))
        .map_err(|e| format!("Failed to create data dir: {e}"))?;

    let wanted: HashSet<&str> = manifest.plugins.iter().map(|p| p.name.as_str()).collect();

    // --- Remove phase ---
    remove_stale_plugins(bakkes_data, &wanted)?;

    // --- Install phase ---
    for plugin in &manifest.plugins {
        install_plugin(bakkes_data, &plugin.name, Path::new(&plugin.source_dir))?;
    }

    log!("Plugin sync complete");
    Ok(())
}

fn remove_stale_plugins(bakkes_data: &Path, wanted: &HashSet<&str>) -> Result<(), String> {
    let plugins_dir = bakkes_data.join("plugins");
    let entries = match fs::read_dir(&plugins_dir) {
        Ok(e) => e,
        Err(_) => return Ok(()),
    };

    for entry in entries.flatten() {
        let name = entry.file_name();
        let name = name.to_string_lossy();
        let Some(plugin_name) = name.strip_suffix(".nix-managed") else {
            continue;
        };

        if !plugin_name.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_') {
            log!("WARNING: Invalid marker name, skipping: {plugin_name}");
            continue;
        }

        if wanted.contains(plugin_name) {
            continue;
        }

        log!("Removing plugin: {plugin_name}");
        let marker_path = entry.path();
        let marker_content = fs::read_to_string(&marker_path).unwrap_or_default();

        for line in marker_content.lines() {
            if line.is_empty() {
                continue;
            }

            let rel = Path::new(line);
            if path_safety::validate_relative(rel).is_err() {
                log!("WARNING: Suspicious path in marker, skipping: {line}");
                continue;
            }

            // Unregister DLL from plugins.cfg
            if let Some(dll_file) = rel.file_name().and_then(|f| f.to_str()) {
                if let Some(dll_stem) = dll_file.strip_suffix(".dll") {
                    if line.starts_with("plugins/") || line.starts_with("plugins\\") {
                        unregister_dll(bakkes_data, dll_stem);
                    }
                }
            }

            let _ = fs::remove_file(bakkes_data.join(rel));
        }

        let _ = fs::remove_file(&marker_path);
    }

    Ok(())
}

fn unregister_dll(bakkes_data: &Path, dll_stem: &str) {
    let dll_lower = dll_stem.to_ascii_lowercase();
    let plugins_cfg = bakkes_data.join("cfg/plugins.cfg");
    let Ok(content) = fs::read_to_string(&plugins_cfg) else {
        return;
    };

    let needle = format!("plugin load {dll_lower}");
    if !content.lines().any(|l| l.trim() == needle) {
        return;
    }

    let filtered: Vec<&str> = content.lines().filter(|l| l.trim() != needle).collect();
    let new_content = filtered.join("\n");
    // Preserve trailing newline if original had one
    let new_content = if content.ends_with('\n') {
        format!("{new_content}\n")
    } else {
        new_content
    };

    if fs::write(&plugins_cfg, &new_content).is_ok() {
        log!("Disabled {dll_lower} in plugins.cfg");
    }
}

struct InstallState {
    marker_lines: Vec<String>,
    copied: u32,
    skipped: u32,
    dll_stem: Option<String>,
}

fn install_plugin(bakkes_data: &Path, name: &str, source_dir: &Path) -> Result<(), String> {
    if !source_dir.is_dir() {
        log!("WARNING: Source dir missing for {name}: {}", source_dir.display());
        return Ok(());
    }

    let start = Instant::now();
    let mut state = InstallState {
        marker_lines: Vec::new(),
        copied: 0,
        skipped: 0,
        dll_stem: None,
    };

    walk_dir(source_dir, source_dir, bakkes_data, &mut state)?;

    let total = state.copied + state.skipped;
    log!("Installed plugin: {name} ({total} files)");

    // Write marker file
    let marker_path = bakkes_data.join(format!("plugins/{name}.nix-managed"));
    let mut marker_content = String::new();
    for line in &state.marker_lines {
        marker_content.push_str(line);
        marker_content.push('\n');
    }
    fs::write(&marker_path, &marker_content)
        .map_err(|e| format!("Failed to write marker for {name}: {e}"))?;

    // Register DLL in plugins.cfg
    if let Some(ref stem) = state.dll_stem {
        register_dll(bakkes_data, stem)?;
    }

    let elapsed = start.elapsed();
    log!("  {name}: {} copied, {} skipped, {:.1}s elapsed", state.copied, state.skipped, elapsed.as_secs_f64());

    Ok(())
}

fn walk_dir(
    root: &Path,
    dir: &Path,
    bakkes_data: &Path,
    state: &mut InstallState,
) -> Result<(), String> {
    let entries = fs::read_dir(dir)
        .map_err(|e| format!("Failed to read dir {}: {e}", dir.display()))?;

    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            walk_dir(root, &path, bakkes_data, state)?;
            continue;
        }

        let rel = path
            .strip_prefix(root)
            .map_err(|e| format!("strip_prefix failed: {e}"))?;

        path_safety::validate_relative(rel)?;

        let dest = bakkes_data.join(rel);
        path_safety::ensure_under(&dest, bakkes_data)?;

        // Track first DLL found
        if state.dll_stem.is_none() {
            if let Some(ext) = rel.extension() {
                if ext.eq_ignore_ascii_case("dll") {
                    if let Some(stem) = rel.file_stem().and_then(|s| s.to_str()) {
                        state.dll_stem = Some(stem.to_ascii_lowercase());
                    }
                }
            }
        }

        let rel_str = rel.to_string_lossy().to_string();
        state.marker_lines.push(rel_str);

        // Create parent dirs
        if let Some(parent) = dest.parent() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("Failed to create dir {}: {e}", parent.display()))?;
        }

        // Copy if newer or missing
        if should_copy(&path, &dest) {
            fs::copy(&path, &dest)
                .map_err(|e| format!("Failed to copy {} -> {}: {e}", path.display(), dest.display()))?;
            state.copied += 1;
        } else {
            state.skipped += 1;
        }
    }

    Ok(())
}

fn should_copy(src: &Path, dest: &Path) -> bool {
    let dest_meta = match fs::metadata(dest) {
        Ok(m) => m,
        Err(_) => return true, // dest doesn't exist
    };
    let src_meta = match fs::metadata(src) {
        Ok(m) => m,
        Err(_) => return true, // err on the side of copying
    };

    // Compare modification times
    match (src_meta.modified(), dest_meta.modified()) {
        (Ok(src_mtime), Ok(dest_mtime)) => src_mtime > dest_mtime,
        _ => true,
    }
}

fn register_dll(bakkes_data: &Path, dll_stem: &str) -> Result<(), String> {
    if !dll_stem.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_') {
        return Ok(());
    }

    let cfg_dir = bakkes_data.join("cfg");
    fs::create_dir_all(&cfg_dir)
        .map_err(|e| format!("Failed to create cfg dir: {e}"))?;

    let plugins_cfg = cfg_dir.join("plugins.cfg");
    let content = fs::read_to_string(&plugins_cfg).unwrap_or_default();
    let load_line = format!("plugin load {dll_stem}");

    if content.lines().any(|l| l.trim() == load_line) {
        return Ok(());
    }

    let mut f = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&plugins_cfg)
        .map_err(|e| format!("Failed to open plugins.cfg: {e}"))?;

    // Ensure trailing newline before appending
    if !content.is_empty() && !content.ends_with('\n') {
        f.write_all(b"\n")
            .map_err(|e| format!("Failed to write to plugins.cfg: {e}"))?;
    }

    writeln!(f, "{load_line}")
        .map_err(|e| format!("Failed to write to plugins.cfg: {e}"))?;
    log!("Enabled {dll_stem} in plugins.cfg");

    Ok(())
}
