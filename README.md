# BakkesMod for NixOS

Declarative [BakkesMod](https://bakkesmod.com/) and plugin management via Home Manager. All **318** plugins from [bakkesplugins.com](https://bakkesplugins.com/) ship with pinned hashes.

## Setup

Requires [Nix flakes](https://wiki.nixos.org/wiki/Flakes), `nixpkgs.config.allowUnfree = true`, and Rocket League installed through Steam and launched once under Proton.

Add the input and the module:

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
            workshopTextures.enable = true;
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

Point Rocket League's **Steam launch options** at the wrapper:

```
bakkes-launcher %command%
```

If steam-config-nix manages that field, set it there instead — the next switch overwrites anything typed by hand:

```nix
programs.steam.config.apps."252950".wrappers = [config.programs.bakkesmod.launcherPackage];
```

Under **Properties → General → Select Launch Option**, pick **Anti-Cheat Disabled**. BakkesMod injects only into that build, and the launcher steps aside on the EAC one. Mods run in freeplay, custom training, LAN, and replays.

The launcher detects Proton, syncs plugins, and injects.

### Launches that skip Steam

RLBot's core starts Rocket League itself, so there is no `%command%` to wrap. Run the injector alongside it instead:

```nix
programs.bakkesmod.injectorPackage  # bakkes-inject
```

It syncs, starts BakkesMod, and stays in the foreground with it, logging to `inject.log`. `--prefix` and `--tool` set the Rocket League prefix and the Proton build to use; both are detected when omitted. `--no-wait` skips waiting for Rocket League and leaves the lifetime to the caller — kill it when the game exits. Only pass it once the game is running: BakkesMod verifies the build id against the Steam manifest it finds through Rocket League's own log, and its safe mode reports itself out of date rather than injecting if it cannot.

> **First install:** plugins activate on the **second** launch — BakkesMod creates its data directory on the first.

## Configuration

Plugins take settings inline:

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

BakkesMod's own settings are grouped by category:

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

Undeclared settings stay untouched, so your manual configuration survives.

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

## Workshop map textures

Custom maps reference UDK editor packages Rocket League omits, so their surfaces load untextured:

```nix
programs.bakkesmod.workshopTextures.enable = true;
```

The launcher links them into the game's `TAGame/CookedPCConsole`, in whichever Steam library it lives, and unlinks them when you turn the option off. Packages the game already ships stay untouched — two under one name causes the "ambiguous package name" crash.

## Finding plugins

```console
$ nix search .# rank
* packages.x86_64-linux.ingamerank
* packages.x86_64-linux.mmr-rank-s7
...
```

## Updating plugins

GitHub Actions refreshes the plugin database daily. To update by hand:

```console
just update
```

| Flag | Description |
|------|-------------|
| `--no-hash` | Fast metadata-only update |
| `--plugin ID` | Update a single plugin |
| `--parallel N` | Parallel downloads (default: 4) |

Flags pass straight through, as in `just update --plugin 123`. The update rewrites `data/plugins.json`, which generates the plugin derivations.

## License

[MIT](LICENSE)
