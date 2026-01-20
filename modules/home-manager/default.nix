# BakkesMod Home Manager module
#
# Provides declarative configuration for BakkesMod and its plugins.
# Usage: add 'bakkes-launcher %command%' to Rocket League Steam launch options.
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
in {
  options.programs.bakkesmod = {
    enable = mkEnableOption "BakkesMod for Rocket League";

    package = mkOption {
      type = types.package;
      default = pkgs.bakkesmod;
      description = "The BakkesMod package to use.";
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

  config = mkIf cfg.enable (let
    scripts = import ./scripts {inherit pkgs lib cfg configLib normalizedPlugins;};
  in {
    home.packages = [scripts.bakkes-launcher];
  });
}
