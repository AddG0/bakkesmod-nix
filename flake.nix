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
          bakkesmod-plugins = final.lib.filterAttrs (n: _: n != "metadata") allPlugins;
        };
      };

      perSystem = {pkgs, ...}: let
        plugins = import ./pkgs/plugins {inherit (pkgs) lib callPackage;};
        pluginPackages = pkgs.lib.filterAttrs (n: _: n != "metadata") plugins;

        updateScript = pkgs.writeShellApplication {
          name = "update-plugins";
          runtimeInputs = with pkgs; [python3 nix];
          text = ''exec python3 ${./scripts/update-plugins.py} "$@"'';
        };
      in {
        packages = {
          default = pkgs.callPackage ./pkgs/bakkesmod.nix {};
          bakkesmod = pkgs.callPackage ./pkgs/bakkesmod.nix {};
        } // pluginPackages;

        checks = {
          bakkesmod = pkgs.callPackage ./pkgs/bakkesmod.nix {};
        } // pluginPackages;

        apps.update = {
          type = "app";
          program = "${updateScript}/bin/update-plugins";
        };
      };
    };
}
