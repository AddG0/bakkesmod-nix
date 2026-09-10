# Behavior test for the injector, up to the point it would actually inject -
# that needs Rocket League, so `proton` and `wine` here are stand-ins.
{
  pkgs,
  src,
}: let
  inherit (pkgs) lib;

  injector =
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
          };
        }
      ];
    })
    .config
    .programs
    .bakkesmod
    .injectorPackage;
in
  pkgs.runCommand "inject-test" {} ''
    set -u
    cd "$(mktemp -d)"

    export HOME="$PWD/home"
    export XDG_STATE_HOME="$PWD/state"
    prefix="$HOME/.steam/steam/steamapps/compatdata/252950"
    log="$XDG_STATE_HOME/bakkesmod/inject.log"

    fail() { echo "FAIL: $1" >&2; ${pkgs.coreutils}/bin/cat "$log" >&2; exit 1; }

    # Records what the injector asks of Proton: `proton` its argv and environment,
    # `wine` its registry calls. Answering `reg query` with nothing takes the
    # injector's "set Windows 10" path.
    fake_tool() {
      rm -rf "$PWD/tool" "$PWD/proton-argv" "$PWD/proton-env" "$PWD/wine-calls"
      mkdir -p "$PWD/tool/files/bin" "$PWD/tool/files/lib"
      {
        echo '#!${pkgs.runtimeShell}'
        echo 'echo "$@" > '"$PWD"'/proton-argv'
        echo 'env > '"$PWD"'/proton-env'
      } > "$PWD/tool/proton"
      {
        echo '#!${pkgs.runtimeShell}'
        echo 'echo "$@" >> '"$PWD"'/wine-calls'
      } > "$PWD/tool/files/bin/wine"
      chmod +x "$PWD/tool/proton" "$PWD/tool/files/bin/wine"
      : > "$PWD/wine-calls"
    }

    setup_prefix() {
      rm -rf "$HOME"
      mkdir -p "$prefix/pfx"
      # An existing data directory is the not-first-run path, where it syncs and
      # goes straight on to launching.
      mkdir -p "$prefix/pfx/drive_c/users/steamuser/AppData/Roaming/bakkesmod/bakkesmod/cfg"
    }

    write_config_info() {
      printf 'GE-Proton\n/fonts/\n%s\n' "$1" > "$prefix/config_info"
    }

    inject() {
      "${injector}/bin/bakkes-inject" "$@" >/dev/null
      echo $?
    }

    echo "declines a prefix that does not exist"
    rm -rf "$HOME"
    [ "$(inject)" = 1 ] || fail "exited 0 without a prefix"
    ${pkgs.gnugrep}/bin/grep -q "no Rocket League prefix" "$log" || fail "did not log the missing prefix"

    echo "declines a prefix Proton has never written config_info into"
    setup_prefix
    [ "$(inject)" = 1 ] || fail "exited 0 without config_info"
    ${pkgs.gnugrep}/bin/grep -q "config_info not found" "$log" || fail "did not log the missing config_info"

    echo "declines a tool with no proton entry point"
    setup_prefix
    [ "$(inject --tool "$PWD/nonexistent")" = 1 ] || fail "exited 0 with an unusable tool"
    ${pkgs.gnugrep}/bin/grep -q "no Proton entry point" "$log" || fail "did not log the unusable tool"

    echo "resolves the tool from config_info when none is given"
    setup_prefix
    fake_tool
    write_config_info "$PWD/tool/files/lib/"
    [ "$(inject --no-wait)" = 0 ] || fail "could not resolve the tool from config_info"
    ${pkgs.gnugrep}/bin/grep -q "Using Proton at $PWD/tool" "$log" || fail "resolved the wrong tool"

    echo "launches BakkesMod through the given tool, ignoring config_info"
    setup_prefix
    fake_tool
    write_config_info "/nix/store/uw1llf1ndn0suchpath-proton/files/lib/"
    [ "$(inject --no-wait --tool "$PWD/tool")" = 0 ] || fail "exited nonzero with an explicit tool"
    ${pkgs.gnugrep}/bin/grep -qE '^run .*/bin/BakkesMod\.exe$' "$PWD/proton-argv" \
      || fail "asked proton for: $(cat "$PWD/proton-argv")"
    ${pkgs.gnugrep}/bin/grep -q 'reg add.*CurrentVersion.*10\.0' "$PWD/wine-calls" \
      || fail "never set the prefix to Windows 10"

    echo "hands BakkesMod the prefix but no app id, so it cannot claim the game's icon"
    setup_prefix
    fake_tool
    # Control: the same assignment reaches an unwrapped call, so an absence below
    # is the injector stripping it and not the test failing to set it.
    SteamAppId=252950 "$PWD/tool/proton" run control >/dev/null
    ${pkgs.gnugrep}/bin/grep -q "^SteamAppId=252950$" "$PWD/proton-env" \
      || fail "the test itself could not put SteamAppId in the environment"
    fake_tool
    [ "$(SteamAppId=252950 SteamGameId=252950 STEAM_COMPAT_APP_ID=252950 \
         STEAM_COMPAT_DATA_PATH="$prefix" inject --no-wait --tool "$PWD/tool")" = 0 ] \
      || fail "exited nonzero"
    ${pkgs.gnugrep}/bin/grep -q "^STEAM_COMPAT_DATA_PATH=$prefix$" "$PWD/proton-env" \
      || fail "did not pass the prefix through to proton"
    for v in SteamAppId SteamGameId STEAM_COMPAT_APP_ID; do
      ${pkgs.gnugrep}/bin/grep -q "^$v=" "$PWD/proton-env" && fail "left $v in BakkesMod's environment"
    done

    echo "waits for the game unless told not to"
    setup_prefix
    fake_tool
    [ "$(BAKKES_WAIT_TIMEOUT=1 inject --tool "$PWD/tool")" = 1 ] || fail "did not wait for the game"
    ${pkgs.gnugrep}/bin/grep -q "Timeout waiting for game" "$log" || fail "did not time out waiting"
    [ ! -f "$PWD/proton-argv" ] || fail "launched BakkesMod before the game existed"

    touch $out
  ''
