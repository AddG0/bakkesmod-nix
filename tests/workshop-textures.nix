# Behavior test for the launcher's workshop-texture linking, run against a
# fake game tree.
{
  pkgs,
  src,
}: let
  inherit (pkgs) lib;

  launcherWith = workshopTextures:
    (lib.evalModules {
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
            inherit workshopTextures;
          };
        }
      ];
    })
    .config
    .programs
    .bakkesmod
    .launcherPackage;

  textures = pkgs.callPackage "${src}/pkgs/workshop-textures.nix" {};
  emptyPackage = pkgs.runCommand "workshop-textures-none" {} "mkdir -p $out";

  enabled = launcherWith {
    enable = true;
    package = textures;
  };
  disabled = launcherWith {enable = false;};
  enabledWithEmptyPackage = launcherWith {
    enable = true;
    package = emptyPackage;
  };

  packageCount = "$(${pkgs.findutils}/bin/find ${textures} -maxdepth 1 -name '*.upk' | wc -l)";
in
  pkgs.runCommand "workshop-textures-test" {} ''
    set -u
    cd "$(mktemp -d)"
    cooked=game/TAGame/CookedPCConsole

    fail() { echo "FAIL: $1" >&2; exit 1; }

    setup() {
      rm -rf game
      mkdir -p game/Binaries/Win64 "$cooked"
      touch game/Binaries/Win64/RocketLeague_EAC.exe
    }

    # The EAC path links textures and then execs, so `true` stands in for Proton.
    launch() {
      XDG_STATE_HOME="$PWD/state" "$1/bin/bakkes-launcher" \
        true waitforexitandrun "$PWD/game/Binaries/Win64/RocketLeague_EAC.exe" \
        || fail "launcher exited $?"
    }

    links() { ${pkgs.findutils}/bin/find "$cooked" -maxdepth 1 -type l | wc -l; }

    echo "links every package in the set, resolving the game directory from %command%"
    setup
    launch ${enabled}
    [ "$(links)" = "${packageCount}" ] || fail "linked $(links), expected ${packageCount}"
    [ -s "$cooked/EngineMaterials.upk" ] || fail "linked file does not resolve to content"

    echo "leaves a package the game ships and links the rest around it"
    setup
    echo shipped > "$cooked/EngineMaterials.upk"
    launch ${enabled}
    [ "$(cat "$cooked/EngineMaterials.upk")" = shipped ] || fail "overwrote the game's own package"
    [ "$(links)" = "$((${packageCount} - 1))" ] || fail "linked $(links) alongside the shipped package"

    echo "replaces a link left pointing at a store path that is gone"
    setup
    ln -s /nix/store/uw1llf1ndn0suchpath-textures/MapTemplates.upk "$cooked/MapTemplates.upk"
    launch ${enabled}
    [ "$(readlink "$cooked/MapTemplates.upk")" = "${textures}/MapTemplates.upk" ] \
      || fail "kept the stale link: $(readlink "$cooked/MapTemplates.upk")"
    [ "$(${pkgs.findutils}/bin/find "$cooked" -maxdepth 1 -xtype l | wc -l)" = 0 ] \
      || fail "left a dangling link behind"

    echo "leaves a link the player pointed somewhere outside the store"
    setup
    ln -s /somewhere/of/their/own.upk "$cooked/NodeBuddies.upk"
    launch ${enabled}
    [ "$(readlink "$cooked/NodeBuddies.upk")" = /somewhere/of/their/own.upk ] \
      || fail "clobbered the player's own link"

    echo "removes its own links once the option is turned off"
    setup
    echo shipped > "$cooked/EngineMaterials.upk"
    launch ${enabled}
    launch ${disabled}
    [ "$(links)" = 0 ] || fail "left $(links) links after being disabled"
    [ "$(cat "$cooked/EngineMaterials.upk")" = shipped ] || fail "removed the game's own package"

    echo "links nothing when the package holds no .upk files"
    setup
    launch ${enabledWithEmptyPackage}
    [ -z "$(ls -A "$cooked")" ] || fail "created $(ls -A "$cooked") from an empty package"

    touch $out
  ''
