# BakkesMod runtime scripts
#
# Three components:
# - bakkes-manifest: JSON manifest of config + plugins for bakkes-sync
# - bakkes-inject: waits for the game, syncs, injects BakkesMod, cleans up
# - bakkes-launcher: Steam launch wrapper that runs the injector alongside the game
{
  pkgs,
  lib,
  cfg,
  configLib,
  normalizedPlugins,
  bakkes-sync,
}:
with lib; let
  generateConfigContent = configLib.generateConfigContent cfg;

  generatePluginConfigs = concatMapStringsSep "\n\n" (p:
    optionalString (p.extraConfig != "") ''
      // Plugin: ${p.plugin.pname or "unknown"}
      ${p.extraConfig}''
  ) normalizedPlugins;

  # Sanitize plugin names for safe usage
  validatePluginName = name:
    if builtins.match "^[a-zA-Z0-9_-]+$" name != null
    then name
    else builtins.replaceStrings [" " "'" "\"" "&" "|" ";" "$" "`" "(" ")" "[" "]" "{" "}" "<" ">" "\\"] ["_" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""] name;

  configContent = ''
    // Nix-managed BakkesMod configuration
    // Generated from Home Manager - do not edit manually
    ${generateConfigContent}
    ${generatePluginConfigs}
  '';

  # Probing "${p.plugin}/share/bakkesmod" here would realise every plugin during
  # evaluation (IFD). Warn rather than drop - bakkes-sync rechecks at runtime,
  # against a store path that exists.
  pluginList =
    map (p:
      warnIf (!(p.plugin.isBakkesModPlugin or false))
      "programs.bakkesmod.plugins: '${p.plugin.pname or p.plugin.name or "<unnamed>"}' lacks passthru.isBakkesModPlugin; it may not install into share/bakkesmod"
      p)
    normalizedPlugins;

  manifestData = builtins.toJSON {
    config_content = configContent;
    plugins = map (p: {
      name = validatePluginName (p.plugin.pname or "unknown");
      source_dir = "${p.plugin}/share/bakkesmod";
    }) pluginList;
  };

  bakkes-manifest = pkgs.writeTextFile {
    name = "bakkes-manifest";
    text = manifestData;
    destination = "/manifest.json";
  };

  # Starts BakkesMod against a Rocket League prefix and stays in the foreground
  # with it. Split out of bakkes-launcher because not every launch goes through
  # Steam: RLBot's core starts the game itself with `proton run`, so no
  # %command% wrapper ever runs.
  bakkes-inject = pkgs.writeShellScriptBin "bakkes-inject" ''
    set -uo pipefail

    # Strip Steam's 32-bit overlay from LD_PRELOAD — it causes harmless but noisy
    # warnings when loading our 64-bit bakkes-sync binary. Must be done in-shell
    # since env -u only takes effect after the dynamic linker has already processed it.
    unset LD_PRELOAD

    # bakkes-launcher exports and truncates its own log; standalone, this owns it.
    if [ -z "''${BAKKES_LOG:-}" ]; then
      BAKKES_LOG="''${XDG_STATE_HOME:-$HOME/.local/state}/bakkesmod/inject.log"
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$BAKKES_LOG")"
      : > "$BAKKES_LOG"
    fi
    log() { echo "[$(${pkgs.coreutils}/bin/date +%H:%M:%S)] $1" >> "$BAKKES_LOG"; }

    PREFIX="''${STEAM_COMPAT_DATA_PATH:-$HOME/.steam/steam/steamapps/compatdata/252950}"
    STEAM_ROOT="''${STEAM_COMPAT_CLIENT_INSTALL_PATH:-$HOME/.steam/steam}"

    # An app id in the environment gives BakkesMod's window the game's WM_CLASS,
    # and whichever maps first owns that taskbar icon. Core exports all three.
    unset SteamAppId SteamGameId STEAM_COMPAT_APP_ID

    TOOL=""
    WAIT_FOR_GAME=true

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --prefix) PREFIX="$2"; shift 2 ;;
        --tool) TOOL="$2"; shift 2 ;;
        # Only for a game already running: started first, BakkesMod cannot read the
        # build id from RL's Launch.log and wedges in OUT_OF_DATE_SAFEMODE_ENABLED.
        --no-wait) WAIT_FOR_GAME=false; shift ;;
        *) echo "bakkes-inject: unknown argument: $1" >&2; exit 2 ;;
      esac
    done

    if [ ! -d "$PREFIX/pfx" ]; then
        log "ERROR: no Rocket League prefix at $PREFIX"
        exit 1
    fi

    # config_info's third line points into <tool>/files; the root is two up.
    if [ -z "$TOOL" ]; then
        if [ ! -f "$PREFIX/config_info" ]; then
            log "ERROR: config_info not found - run Rocket League once first"
            exit 1
        fi
        libdir=$(${pkgs.gnused}/bin/sed -n '3p' "$PREFIX/config_info" 2>/dev/null) || libdir=""
        if [ -n "$libdir" ]; then
            TOOL=$(${pkgs.coreutils}/bin/dirname "$(${pkgs.coreutils}/bin/dirname "$libdir")")
        fi
    fi

    if [ ! -x "$TOOL/proton" ]; then
        log "ERROR: no Proton entry point at ''${TOOL:-<unset>}/proton"
        exit 1
    fi

    log "Using Proton at $TOOL, prefix $PREFIX"

    # Wine 10 folded wine64 into a single WoW64 `wine`; Proton 11 ships only that.
    WINE="$TOOL/files/bin/wine64"
    [ -x "$WINE" ] || WINE="$TOOL/files/bin/wine"

    # BakkesMod requires Windows 10
    WIN_VER=$(WINEPREFIX="$PREFIX/pfx" "$WINE" reg query 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentVersion 2>/dev/null | ${pkgs.gnugrep}/bin/grep "10.0" || echo "")
    if [ -z "$WIN_VER" ]; then
        log "Setting Windows version to 10..."
        WINEPREFIX="$PREFIX/pfx" "$WINE" reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentVersion /t REG_SZ /d "10.0" /f >/dev/null 2>&1 || true
        WINEPREFIX="$PREFIX/pfx" "$WINE" reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentBuild /t REG_SZ /d "19045" /f >/dev/null 2>&1 || true
    fi

    # Drive letter is the Steam library's, not always Z:. The backslash is
    # what excludes wine's steam.exe, whose cmdline also ends in the exe name.
    game_running() {
        ${pkgs.procps}/bin/pgrep -f '[A-Za-z]:.*\\RocketLeague\.exe' >/dev/null 2>&1
    }

    if [ "$WAIT_FOR_GAME" = true ]; then
        log "Waiting for Rocket League..."
        # 0 waits indefinitely.
        WAIT_LIMIT=$(( ''${BAKKES_WAIT_TIMEOUT:-300} * 2 ))
        WAIT_COUNT=0
        while ! game_running; do
            ${pkgs.coreutils}/bin/sleep 0.5
            WAIT_COUNT=$((WAIT_COUNT + 1))
            if [ "$WAIT_LIMIT" -gt 0 ] && [ "$WAIT_COUNT" -ge "$WAIT_LIMIT" ]; then
                log "ERROR: Timeout waiting for game"
                exit 1
            fi
        done
        GAME_PID=$(${pkgs.procps}/bin/pgrep -f '[A-Za-z]:.*\\RocketLeague\.exe')
        log "Game detected (PID: $GAME_PID)"
    fi

    BAKKES_DATA="$PREFIX/pfx/drive_c/users/steamuser/AppData/Roaming/bakkesmod/bakkesmod"

    FIRST_RUN=false
    if [ ! -d "$BAKKES_DATA" ]; then
        FIRST_RUN=true
        log "First run - plugins will load on next launch"
    else
        log "Syncing config and plugins..."
        ${bakkes-sync}/bin/bakkes-sync config ${bakkes-manifest}/manifest.json "$BAKKES_DATA" >> "$BAKKES_LOG" 2>&1 || log "ERROR: Config sync failed"
        ${bakkes-sync}/bin/bakkes-sync plugins ${bakkes-manifest}/manifest.json "$BAKKES_DATA" >> "$BAKKES_LOG" 2>&1 || log "ERROR: Plugin sync failed"
    fi

    log "Launching BakkesMod..."
    STEAM_COMPAT_DATA_PATH="$PREFIX" \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT" \
    WINEDEBUG=-all WINEFSYNC=1 \
      "$TOOL/proton" run ${cfg.package}/bin/BakkesMod.exe >> "$BAKKES_LOG" 2>&1 &
    BAKKES_PID=$!
    log "BakkesMod PID: $BAKKES_PID"
    trap 'kill "$BAKKES_PID" 2>/dev/null || true' TERM INT

    # On first run: wait for BakkesMod to create defaults, then sync for next launch
    if [ "$FIRST_RUN" = true ]; then
        log "Waiting for BakkesMod to initialize..."
        WAIT_COUNT=0
        while [ ! -d "$BAKKES_DATA/cfg" ] && [ "$WAIT_COUNT" -lt 60 ]; do
            kill -0 "$BAKKES_PID" 2>/dev/null || { log "ERROR: BakkesMod died"; exit 1; }
            ${pkgs.coreutils}/bin/sleep 1
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done

        if [ -d "$BAKKES_DATA/cfg" ]; then
            log "Syncing config and plugins for next launch..."
            ${bakkes-sync}/bin/bakkes-sync config ${bakkes-manifest}/manifest.json "$BAKKES_DATA" >> "$BAKKES_LOG" 2>&1 || log "ERROR: Config sync failed"
            ${bakkes-sync}/bin/bakkes-sync plugins ${bakkes-manifest}/manifest.json "$BAKKES_DATA" >> "$BAKKES_LOG" 2>&1 || log "ERROR: Plugin sync failed"
        fi
    fi

    if [ "$WAIT_FOR_GAME" = false ]; then
        log "Ready! BakkesMod owns the wait for the game."
        wait "$BAKKES_PID"
        exit
    fi

    ${pkgs.coreutils}/bin/sleep 2
    ${pkgs.wmctrl}/bin/wmctrl -a "Rocket League" 2>/dev/null || log "Could not refocus game window"

    log "Ready! Waiting for game to exit..."
    while kill -0 "$GAME_PID" 2>/dev/null; do
        ${pkgs.coreutils}/bin/sleep 0.5
    done

    log "Game exited, stopping BakkesMod..."
    kill "$BAKKES_PID" 2>/dev/null || true
    ${pkgs.coreutils}/bin/sleep 0.5
    kill -9 "$BAKKES_PID" 2>/dev/null || true
    log "Session ended"
  '';

  # Steam launch wrapper: bakkes-launcher %command%
  bakkes-launcher = pkgs.writeShellScriptBin "bakkes-launcher" ''
    set -uo pipefail

    BAKKES_LOG="''${XDG_STATE_HOME:-$HOME/.local/state}/bakkesmod/launcher.log"
    mkdir -p "$(dirname "$BAKKES_LOG")"
    : > "$BAKKES_LOG"  # Truncate log at session start
    export BAKKES_LOG
    log() { echo "[$(date +%H:%M:%S)] $1" >> "$BAKKES_LOG"; }

    log "=== BakkesMod Launcher Started ==="
    log "Args: $*"

    # Inert data, so this runs ahead of the EAC bail-out. They belong in the
    # game's install - not the prefix - on whichever library %command% points at.
    COOKED_DIR=""
    for arg in "$@"; do
      case "$arg" in
        */Binaries/Win64/RocketLeague*.exe)
          COOKED_DIR="''${arg%/Binaries/*}/TAGame/CookedPCConsole"
          break
          ;;
      esac
    done

    if [ -d "$COOKED_DIR" ]; then
      # Clearing ours first drops a stale store path and leaves only the game's
      # own files under these names - which plain `ln -s` (no -f) won't overwrite.
      # Two packages under one name is an "ambiguous package name" crash.
      ${pkgs.findutils}/bin/find "$COOKED_DIR" -maxdepth 1 -name '*.upk' -lname '/nix/store/*' -delete
      ${optionalString cfg.workshopTextures.enable ''
      ${pkgs.findutils}/bin/find ${cfg.workshopTextures.package} -maxdepth 1 -name '*.upk' \
        -exec ${pkgs.coreutils}/bin/ln -s -t "$COOKED_DIR" {} + 2>>"$BAKKES_LOG"
      log "Workshop textures linked into $COOKED_DIR"
    ''}
    fi

    # BakkesMod cannot inject into Steam's EAC executable; the "Anti-Cheat
    # Disabled" launch option runs RocketLeague.exe instead.
    case "$*" in
      *RocketLeague_EAC.exe*)
        log "EAC build detected - BakkesMod cannot inject"
        log "Steam > Rocket League > Properties > Select Launch Option >"
        log "  'Rocket League with Anti-Cheat Disabled (Mods and Limited Online Play)'"
        exec "$@"
        ;;
    esac

    ${bakkes-inject}/bin/bakkes-inject &

    "$@"
  '';
in {
  inherit bakkes-inject bakkes-launcher;
}
