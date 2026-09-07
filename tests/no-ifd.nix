# Regression test: evaluating the Home Manager module must not build anything.
# Run under `allow-import-from-derivation = false` - see `nix run .#check-no-ifd`.
{
  pkgs,
  src,
}: let
  inherit (pkgs) lib;

  plugins = import "${src}/pkgs/plugins" {inherit (pkgs) lib callPackage;};

  # `home.packages` is the only option the module writes, so stub that rather
  # than pull in Home Manager.
  eval = lib.evalModules {
    modules = [
      (import "${src}/modules/home-manager")
      {
        options.home.packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [];
        };

        config._module.args.pkgs = pkgs;
        config.programs.bakkesmod = {
          enable = true;
          # The option default would drag this test's `pkgs` through the overlay.
          package = pkgs.callPackage "${src}/pkgs/bakkesmod.nix" {};
          plugins = [plugins.rocketstats];
          workshopTextures = {
            enable = true;
            package = pkgs.callPackage "${src}/pkgs/workshop-textures.nix" {};
          };
        };
      }
    ];
  };
in
  # `drvPath`, not `name`: instantiating the derivation is what forced the
  # plugin build. Joined into one string so `nix eval --raw` forces every
  # element - a lazy list member that throws prints as «error: …» and exits 0.
  lib.concatMapStringsSep "\n" (p: p.drvPath) eval.config.home.packages
