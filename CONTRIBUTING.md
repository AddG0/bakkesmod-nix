# Contributing to BakkesMod for NixOS

Thanks for your interest in contributing!

## Development Setup

Clone the repository:
```bash
git clone https://github.com/AddG0/bakkesmod-nix
cd bakkesmod-nix
```

## Testing Changes

`just --list` shows every recipe, grouped:

| Recipe | Does |
|--------|------|
| `just test` | Run the behavior tests — Rust unit tests, cvar generation, texture linking, IFD |
| `just check` | Build every package and run the flake checks |
| `just check-ifd` | Check that the module evaluates without import-from-derivation |
| `just build` | Build `bakkesmod`; `just build rocketstats` builds any other output |
| `just fmt` | Format every Nix file with alejandra |
| `just logs` | Print the launcher log — attach this to bug reports |
| `just clean-bakkes` | Delete BakkesMod's data directory to retest a first install |

To try module changes against your own configuration, point the input at your
checkout:

```nix
inputs.bakkesmod-nix.url = "path:/path/to/bakkesmod-nix";
```

`path:` inputs are pinned by hash, so run `nix flake update bakkesmod-nix` after
each edit or your rebuild will silently use the previous copy.

## Adding a New Plugin

Plugins come from bakkesplugins.com automatically — see **Updating plugins** in
the README for `just update` and its flags.

## Adding New Configuration Options

1. Add the option definition in `modules/home-manager/options/`
2. Add the config generation in `modules/home-manager/lib/config.nix`
3. Confirm with `just check`

## Code Style

- Run `just fmt` before committing (alejandra)
- Keep derivations minimal and focused
- Document non-obvious configuration options

## Pull Request Guidelines

1. Create a feature branch from `main`
2. Make your changes
3. Run `just check` to validate
4. Submit a PR with a clear description of the changes

## Reporting Issues

When reporting issues, please include:
- Your NixOS/Home Manager version
- Relevant configuration snippets
- Output of `just logs` if it's a runtime issue
- Steps to reproduce the problem
