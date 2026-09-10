# BakkesMod Home Manager module
#
# Provides declarative configuration for BakkesMod and its plugins.
# Usage: add 'bakkes-launcher %command%' to Rocket League Steam launch options.
# A launch that bypasses Steam entirely calls bakkes-inject instead.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.bakkesmod;
  configLib = import ./lib/config.nix {inherit lib;};

  # Plugins can be specified as just a package or with extraConfig
  pluginModule = types.submodule {
    options = {
      plugin = mkOption {
        type = types.package;
        description = "The plugin package to install.";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Plugin-specific cvars to set on load.";
        example = ''
          cl_dejavu_enabled "1"
          cl_dejavu_scale "2.0"
        '';
      };
    };
  };

  # Normalize: package -> { plugin, extraConfig }
  normalizePlugin = p:
    if p ? plugin
    then p
    else {plugin = p; extraConfig = "";};

  normalizedPlugins = map normalizePlugin cfg.plugins;

  bakkes-sync = pkgs.callPackage ../../pkgs/bakkes-sync/package.nix {};
  scripts = import ./scripts {inherit pkgs lib cfg configLib normalizedPlugins bakkes-sync;};
in {
  options.programs.bakkesmod = {
    enable = mkEnableOption "BakkesMod for Rocket League";

    package = mkOption {
      type = types.package;
      default = pkgs.bakkesmod;
      description = "The BakkesMod package to use.";
    };

    launcherPackage = mkOption {
      type = types.package;
      default = scripts.bakkes-launcher;
      defaultText = literalExpression "the generated bakkes-launcher";
      readOnly = true;
      description = ''
        The generated Steam launch wrapper, for wiring into a declarative Steam
        config (e.g. steam-config-nix's
        `programs.steam.config.apps."252950".wrappers`) rather than typing
        `bakkes-launcher %command%` into the launch options by hand.
      '';
    };

    injectorPackage = mkOption {
      type = types.package;
      default = scripts.bakkes-inject;
      defaultText = literalExpression "the generated bakkes-inject";
      readOnly = true;
      description = ''
        BakkesMod's injector, for starting it outside a Steam launch - RLBot's
        core launches Rocket League itself, so no `%command%` wrapper runs.

        Syncs config and plugins, starts BakkesMod, and stays in the foreground
        with it. `--prefix` and `--tool` set the Rocket League prefix and the
        Proton build to use; both are detected when omitted.

        `--no-wait` skips waiting for Rocket League, leaving the lifetime to the
        caller. Only pass it once the game is running: BakkesMod verifies the
        build id against the Steam manifest it finds through Rocket League's own
        log, and its safe mode reports itself out of date rather than injecting
        if it cannot.
      '';
    };

    plugins = mkOption {
      type = types.listOf (types.either types.package pluginModule);
      default = [];
      example = literalExpression ''
        with pkgs.bakkesmod-plugins; [
          rocketstats
          {
            plugin = deja-vu-player-tracking;
            extraConfig = '''
              cl_dejavu_enabled "1"
              cl_dejavu_scale "2.0"
            ''';
          }
        ]
      '';
      description = ''
        Plugins to install. Can be a package or { plugin, extraConfig }.
        Managed declaratively - plugins removed from this list are uninstalled.
      '';
    };

    workshopTextures = {
      enable = mkEnableOption ''
        workshop map textures. Rocket League doesn't ship the UDK editor
        packages custom maps are built against, so their surfaces load
        untextured. The launcher links them into the game's
        `TAGame/CookedPCConsole`, and unlinks them again when this is off
      '';

      package = mkOption {
        type = types.package;
        default = pkgs.rocketleague-workshop-textures;
        defaultText = literalExpression "pkgs.rocketleague-workshop-textures";
        description = "Flat directory of `.upk` texture packages to link in.";
      };
    };

    config = {
      gui = import ./options/gui.nix {inherit lib;};
      console = import ./options/console.nix {inherit lib;};
      ranked = import ./options/ranked.nix {inherit lib;};
      replay = import ./options/replay.nix {inherit lib;};
      freeplay = import ./options/freeplay.nix {inherit lib;};
      training = import ./options/training.nix {inherit lib;};
      anonymizer = import ./options/anonymizer.nix {inherit lib;};
      loadout = import ./options/loadout.nix {inherit lib;};
      camera = import ./options/camera.nix {inherit lib;};
      dollyCam = import ./options/dollycam.nix {inherit lib;};
      mechanical = import ./options/mechanical.nix {inherit lib;};
      rcon = import ./options/rcon.nix {inherit lib;};
      misc = import ./options/misc.nix {inherit lib;};
      queueMenu = import ./options/queue-menu.nix {inherit lib;};

      pluginFavorites = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Favorite plugins list (semicolon-separated).";
      };

      extraConfig = mkOption {
        type = types.attrsOf (types.oneOf [types.bool types.int types.float types.str]);
        default = {};
        example = literalExpression ''
          {
            "cl_dejavu_enabled" = true;
            "cl_dejavu_scale" = 2.0;
          }
        '';
        description = "Additional cvars to set (for plugins or BakkesMod).";
      };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [cfg.launcherPackage cfg.injectorPackage];
  };
}
