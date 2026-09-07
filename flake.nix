{
  description = "BakkesMod for NixOS - declarative configuration and plugin management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      flake = {
        homeManagerModules = {
          bakkesmod = import ./modules/home-manager;
          default = inputs.self.homeManagerModules.bakkesmod;
        };

        overlays.default = final: prev: let
          allPlugins = import ./pkgs/plugins {inherit (final) lib callPackage;};
        in {
          bakkesmod = final.callPackage ./pkgs/bakkesmod.nix {};
          bakkes-sync = final.callPackage ./pkgs/bakkes-sync/package.nix {};
          rocketleague-workshop-textures = final.callPackage ./pkgs/workshop-textures.nix {};
          bakkesmod-plugins = final.lib.filterAttrs (n: _: n != "metadata") allPlugins;
        };
      };

      perSystem = {
        pkgs,
        system,
        ...
      }: let
        plugins = import ./pkgs/plugins {inherit (pkgs) lib callPackage;};
        pluginPackages = pkgs.lib.filterAttrs (n: _: n != "metadata") plugins;

        updateScript = pkgs.writeShellApplication {
          name = "update-plugins";
          runtimeInputs = with pkgs; [python3 nix];
          text = ''exec python3 ${./scripts/update-plugins.py} "$@"'';
        };
        bakkesmod = pkgs.callPackage ./pkgs/bakkesmod.nix {};
        bakkes-sync = pkgs.callPackage ./pkgs/bakkes-sync/package.nix {};
        rocketleague-workshop-textures = pkgs.callPackage ./pkgs/workshop-textures.nix {};

        # Not a `checks` entry: disproving IFD needs a nested `nix eval` with
        # the option off, which the build sandbox has no store access to run.
        ifdCheck = pkgs.writeShellApplication {
          name = "check-no-ifd";
          runtimeInputs = [pkgs.nix];
          text = ''
            # --impure only to read the store paths below; they are pinned here.
            nix eval --impure --raw --option allow-import-from-derivation false --expr \
              'import ${inputs.self}/tests/no-ifd.nix {
                 pkgs = import ${pkgs.path} {
                   system = "${system}";
                   config.allowUnfree = true;
                 };
                 src = ${inputs.self};
               }' >/dev/null
            echo "OK: Home Manager module evaluates without import-from-derivation"
          '';
        };
      in {
        # Everything here is unfree; without this, builds need NIXPKGS_ALLOW_UNFREE.
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        packages =
          {
            default = bakkesmod;
            inherit bakkesmod bakkes-sync rocketleague-workshop-textures;
          }
          // pluginPackages;

        checks =
          {
            inherit bakkesmod bakkes-sync rocketleague-workshop-textures;
            workshop-textures-test = pkgs.callPackage ./tests/workshop-textures.nix {src = inputs.self;};
            config-generation-test = pkgs.callPackage ./tests/config-generation.nix {src = inputs.self;};
          }
          // pluginPackages;

        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          inputsFrom = [bakkes-sync];
        };

        apps = {
          update = {
            type = "app";
            program = "${updateScript}/bin/update-plugins";
          };
          check-no-ifd = {
            type = "app";
            program = "${ifdCheck}/bin/check-no-ifd";
          };
        };
      };
    };
}
