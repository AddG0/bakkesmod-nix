# BakkesMod for NixOS

Declarative [BakkesMod](https://bakkesmod.com/) configuration and plugin management for NixOS via Home Manager. All **318** plugins from [bakkesplugins.com](https://bakkesplugins.com/) are available with pre-computed hashes.

## Quick Start

### Prerequisites

- [Nix flakes](https://wiki.nixos.org/wiki/Flakes) enabled
- Unfree packages allowed (`nixpkgs.config.allowUnfree = true`)
- Rocket League installed via Steam (launched at least once with Proton)

### Setup

Add the flake input and Home Manager module:

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
          nixpkgs.overlays = [ bakkesmod-nix.overlays.default ];

          programs.bakkesmod = {
            enable = true;
            plugins = with bakkesmod-nix.packages.x86_64-linux; [
              rocketstats
              deja-vu-player-tracking
            ];
          };
        }
      ];
    };
  };
}
```

Then set your Rocket League **Steam launch options** to:

```
bakkes-launcher %command%
```

That's it. The launcher handles Proton detection, plugin sync, and BakkesMod injection automatically.

> **First install:** plugins activate on the **second** launch, since BakkesMod needs to create its data directory first.

## Configuration

### Plugins with settings

```nix
programs.bakkesmod.plugins = with pkgs.bakkesmod-plugins; [
  rocketstats
  bakkesmod-graphs

  {
    plugin = deja-vu-player-tracking;
    extraConfig = ''
      cl_dejavu_enabled "1"
      cl_dejavu_scale "2.0"
    '';
  }
];
```

### BakkesMod settings

```nix
programs.bakkesmod.config = {
  gui.scale = 1.0;
  console.enabled = true;
  ranked.showRanks = true;
  ranked.autoGG = true;
  extraConfig = {
    "cl_dejavu_ingame" = true;
  };
};
```

Settings you don't declare are left untouched — your manual BakkesMod configuration is preserved.

### Available config categories

| Category | Examples |
|----------|----------|
| `gui` | Theme, scale, alpha |
| `console` | Key binding, size, position |
| `ranked` | Show ranks, auto-GG, auto-queue |
| `replay` | Auto-upload, naming templates |
| `freeplay` | Goal detection, boost limits |
| `training` | Shuffle, mirror, clock |
| `anonymizer` | Player name hiding modes |
| `loadout` | Car colors, item mods |
| `camera` | Clip to field, goal replay |
| `dollyCam` | Interpolation, rendering |
| `mechanical` | Input restrictions |
| `rcon` | Remote console |
| `misc` | FPS counter, system time |
| `extraConfig` | Arbitrary cvars (escape hatch) |

## Finding plugins

Search by name:

```console
$ nix search .# rank
* packages.x86_64-linux.ingamerank
* packages.x86_64-linux.mmr-rank-s7
...
```

## Updating plugins

The plugin database updates daily via GitHub Actions. To update manually:

```console
nix run .#update
```

| Flag | Description |
|------|-------------|
| `--no-hash` | Fast metadata-only update |
| `--plugin ID` | Update a single plugin |
| `--parallel N` | Parallel downloads (default: 4) |

## License

[MIT](LICENSE)
