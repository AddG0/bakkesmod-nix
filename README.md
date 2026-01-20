# BakkesMod for NixOS

This flake provides Nix expressions for [BakkesMod](https://bakkesmod.com/) and plugins from [bakkesplugins.com](https://bakkesplugins.com/). A [GitHub Action](https://github.com/features/actions) updates the plugin database daily.

All **318** plugins from bakkesplugins.com are available with pre-computed hashes for reproducible builds. Configure BakkesMod settings declaratively through your Nix configuration.

## Prerequisites

### Enable flakes

Read about [Nix flakes](https://wiki.nixos.org/wiki/Flakes) and [set them up](https://wiki.nixos.org/wiki/Flakes#Setup).

### Allow unfree packages

BakkesMod and its plugins are unfree. Enable unfree packages in your configuration:

```nix
nixpkgs.config.allowUnfree = true;
```

### Install Rocket League via Steam

BakkesMod requires Rocket League installed through Steam with Proton. Run Rocket League at least once to initialize the Proton prefix.

## Installation

### As a flake input

Add `bakkesmod-nix` to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    bakkesmod-nix.url = "github:AddG0/bakkesmod-nix";
  };

  outputs = { nixpkgs, home-manager, bakkesmod-nix, ... }: {
    homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
      modules = [
        bakkesmod-nix.homeManagerModules.default
        {
          programs.bakkesmod = {
            enable = true;
            plugins = with bakkesmod-nix.packages.x86_64-linux; [
              rocketstats
              {
                plugin = deja-vu-player-tracking;
                extraConfig = ''
                  cl_dejavu_enabled "1"
                '';
              }
            ];
          };
        }
      ];
    };
  };
}
```

### Using the overlay

```nix
{
  nixpkgs.overlays = [ bakkesmod-nix.overlays.default ];
}
```

This provides `pkgs.bakkesmod` and `pkgs.bakkesmod-plugins`.

## Configuration

### Basic example

```nix
programs.bakkesmod = {
  enable = true;

  plugins = with pkgs.bakkesmod-plugins; [
    # Simple plugins
    rocketstats
    bakkesmod-graphs

    # Plugin with configuration
    {
      plugin = deja-vu-player-tracking;
      extraConfig = ''
        cl_dejavu_enabled "1"
        cl_dejavu_ingame "1"
        cl_dejavu_scale "2.0"
      '';
    }

    # Another configured plugin
    {
      plugin = alphaconsole-for-bakkesmod;
      extraConfig = ''
        acplugin_enablealiases "1"
      '';
    }
  ];

  config = {
    gui.scale = 1.0;
    console.enabled = true;
    ranked.showRanks = true;
    ranked.autoGG = true;
  };
};
```

### Available options

| Category | Description |
|----------|-------------|
| `config.gui` | GUI appearance (theme, scale, alpha) |
| `config.console` | Console settings (key, size, position) |
| `config.ranked` | Ranked features (show ranks, auto-GG, auto-queue) |
| `config.replay` | Replay settings (auto-upload, naming) |
| `config.freeplay` | Freeplay options (goal detection, boost limits) |
| `config.training` | Training pack settings |
| `config.anonymizer` | Player anonymization |
| `config.loadout` | Car customization |
| `config.camera` | Camera settings |
| `config.dollyCam` | DollyCam for replays |
| `config.mechanical` | Input restrictions |
| `config.rcon` | Remote console |
| `config.misc` | Miscellaneous options |
| `config.extraConfig` | Arbitrary cvars |

### Steam launch options

Add the launcher to your Rocket League launch options in Steam:

```
bakkes-launcher %command%
```

The launcher automatically:
- Detects your Proton installation
- Waits for Rocket League to start
- Launches BakkesMod with the correct Wine prefix
- Syncs your Nix-managed plugins and configuration

> [!NOTE]
> Your manual BakkesMod settings and plugins are preserved. Nix only manages what you declare.

> [!IMPORTANT]
> On first install, plugins will auto-enable on the **second launch** of Rocket League. This is because BakkesMod needs to create its data directory before plugins can be registered. After the initial setup, this is no longer an issue.

## Explore

### List available plugins

```console
nix eval .#packages.x86_64-linux --apply 'x: builtins.filter (n: builtins.substring 0 9 n == "bakkesmod") (builtins.attrNames x)'
```

### Search plugins by name

```console
nix eval .#packages.x86_64-linux --apply 'x: builtins.filter (n: builtins.match ".*rank.*" n != null) (builtins.attrNames x)'
```

## Updating plugins

The plugin database is updated daily via GitHub Actions. To manually update:

```console
nix run .#update
```

Options:
- `--no-hash` - Fast metadata-only update (skip hash calculation)
- `--plugin ID` - Update a specific plugin by ID
- `--parallel N` - Number of parallel downloads (default: 4)

## Project structure

```
bakkesmod-nix/
├── data/
│   └── plugins.json          # Plugin metadata with hashes
├── modules/
│   └── home-manager/         # Home Manager module
│       ├── default.nix
│       ├── lib/              # Config generation utilities
│       ├── options/          # Option definitions
│       └── scripts/          # Launcher and sync scripts
├── pkgs/
│   ├── bakkesmod.nix         # BakkesMod package
│   └── plugins/              # Plugin derivations
├── scripts/
│   └── update-plugins.py     # Plugin database updater
└── flake.nix
```

## License

[MIT](LICENSE)

## Credits

- [BakkesMod](https://bakkesmod.com/)
- [bakkesplugins.com](https://bakkesplugins.com/)
