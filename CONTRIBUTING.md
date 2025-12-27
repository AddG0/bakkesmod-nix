# Contributing to BakkesMod for NixOS

Thanks for your interest in contributing!

## Development Setup

Clone the repository:
```bash
git clone https://github.com/AddG0/bakkesmod-nix
cd bakkesmod-nix
```

## Testing Changes

### Validate the flake
```bash
nix flake check
```

### Build BakkesMod
```bash
nix build .#bakkesmod
```

### Build a specific plugin
```bash
nix build .#rocketstats
```

### Test the Home Manager module
Add the local flake to your Home Manager configuration:
```nix
{
  inputs.bakkesmod-nix.url = "path:/path/to/bakkesmod-nix";
}
```

## Adding a New Plugin

Plugins are automatically fetched from bakkesplugins.com. To manually add or update plugins:

```bash
# Update all plugins
nix run .#update

# Update a specific plugin by ID
nix run .#update -- --plugin 123

# Fast metadata-only update (skip hash calculation)
nix run .#update -- --no-hash
```

The update script modifies `data/plugins.json` which is used to generate plugin derivations.

## Adding New Configuration Options

1. Add the option definition in `modules/home-manager/options/`
2. Add the config generation in `modules/home-manager/lib/config.nix`
3. Test with `nix flake check`

## Code Style

- Run `nix fmt` before committing (uses alejandra for Nix files)
- Keep derivations minimal and focused
- Document non-obvious configuration options

## Pull Request Guidelines

1. Create a feature branch from `main`
2. Make your changes
3. Run `nix flake check` to validate
4. Submit a PR with a clear description of the changes

## Reporting Issues

When reporting issues, please include:
- Your NixOS/Home Manager version
- Relevant configuration snippets
- Output of `cat ~/.local/state/bakkesmod/launcher.log` if it's a runtime issue
- Steps to reproduce the problem
