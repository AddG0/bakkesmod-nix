# BakkesMod runtime scripts
#
# Two components:
# - bakkes-manifest: JSON manifest of config + plugins for bakkes-sync
# - bakkes-launcher: Steam launch wrapper that starts BakkesMod with the game
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

  pluginList = filter (p: builtins.pathExists "${p.plugin}/share/bakkesmod") normalizedPlugins;

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
in {
  # Steam launch wrapper: bakkes-launcher %command%
  bakkes-launcher = pkgs.writeShellScriptBin "bakkes-launcher" ''
    set -uo pipefail

    BAKKES_LOG="''${XDG_STATE_HOME:-$HOME/.local/state}/bakkesmod/launcher.log"
    mkdir -p "$(dirname "$BAKKES_LOG")"
    : > "$BAKKES_LOG"  # Truncate log at session start
    export BAKKES_LOG
    log() { echo "[$(date +%H:%M:%S)] $1" >> "$BAKKES_LOG"; }
    export -f log

    log "=== BakkesMod Launcher Started ==="
    log "Args: $*"

    RL_PREFIX="$HOME/.steam/steam/steamapps/compatdata/252950"

    if [ ! -d "$RL_PREFIX" ]; then
        log "ERROR: Rocket League not found at $RL_PREFIX"
        log "Launching without BakkesMod..."
        exec "$@"
    fi

    if [ ! -f "$RL_PREFIX/config_info" ]; then
        log "ERROR: config_info not found - run Rocket League once first"
        log "Launching without BakkesMod..."
        exec "$@"
    fi

    detect_proton() {
        local config_info="$1"
        [ ! -f "$config_info" ] || [ ! -r "$config_info" ] && return 1

        local proton_path
        proton_path=$(${pkgs.gnused}/bin/sed -n '3p' "$config_info" 2>/dev/null) || return 1
        [ -z "$proton_path" ] && return 1

        proton_path=$(dirname "$proton_path" 2>/dev/null) || return 1

        if [ -d "$proton_path" ] && [ -x "$proton_path/bin/wine64" ]; then
            echo "$proton_path"
            return 0
        fi
        return 1
    }

    if ! PROTON=$(detect_proton "$RL_PREFIX/config_info"); then
        log "ERROR: Could not detect Proton"
        log "Launching without BakkesMod..."
        exec "$@"
    fi

    log "Using Proton at $PROTON"

    # BakkesMod requires Windows 10
    if [ -d "$RL_PREFIX/pfx" ]; then
        WIN_VER=$(WINEPREFIX="$RL_PREFIX/pfx" "$PROTON/bin/wine64" reg query 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentVersion 2>/dev/null | ${pkgs.gnugrep}/bin/grep "10.0" || echo "")
        if [ -z "$WIN_VER" ]; then
            log "Setting Windows version to 10..."
            WINEPREFIX="$RL_PREFIX/pfx" "$PROTON/bin/wine64" reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentVersion /t REG_SZ /d "10.0" /f >/dev/null 2>&1 || true
            WINEPREFIX="$RL_PREFIX/pfx" "$PROTON/bin/wine64" reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentBuild /t REG_SZ /d "19045" /f >/dev/null 2>&1 || true
        fi
    fi

    # Background: wait for game, then inject BakkesMod
    (
        # Strip Steam's 32-bit overlay from LD_PRELOAD — it causes harmless but noisy
        # warnings when loading our 64-bit bakkes-sync binary. Must be done in-shell
        # since env -u only takes effect after the dynamic linker has already processed it.
        unset LD_PRELOAD

        log "Waiting for Rocket League..."

        # Detect actual game process (Wine Z:\ path), not wrappers
        game_running() {
            ${pkgs.procps}/bin/pgrep -f "Z:.*RocketLeague\\.exe" >/dev/null 2>&1
        }

        WAIT_COUNT=0
        while ! game_running; do
            ${pkgs.coreutils}/bin/sleep 0.5
            WAIT_COUNT=$((WAIT_COUNT + 1))
            if [ "$WAIT_COUNT" -gt 600 ]; then
                log "ERROR: Timeout waiting for game"
                exit 1
            fi
        done

        GAME_PID=$(${pkgs.procps}/bin/pgrep -f "Z:.*RocketLeague\\.exe")
        log "Game detected (PID: $GAME_PID), initializing..."
        BAKKES_DATA="$RL_PREFIX/pfx/drive_c/users/steamuser/AppData/Roaming/bakkesmod/bakkesmod"

        FIRST_RUN=false
        if [ ! -d "$BAKKES_DATA" ]; then
            FIRST_RUN=true
            log "First run - plugins will load on next launch"
        else
            log "Syncing config and plugins..."
            ${bakkes-sync}/bin/bakkes-sync config ${bakkes-manifest}/manifest.json "$BAKKES_DATA" >> "$BAKKES_LOG" 2>&1 || log "ERROR: Config sync failed"
            ${bakkes-sync}/bin/bakkes-sync plugins ${bakkes-manifest}/manifest.json "$BAKKES_DATA" >> "$BAKKES_LOG" 2>&1 || log "ERROR: Plugin sync failed"
        fi

        if ! kill -0 "$GAME_PID" 2>/dev/null; then
            log "ERROR: Game exited during init"
            exit 1
        fi

        log "Launching BakkesMod..."
        WINEDEBUG=-all WINEFSYNC=1 WINEPREFIX="$RL_PREFIX/pfx" "$PROTON/bin/wine64" ${cfg.package}/bin/BakkesMod.exe 2>/dev/null &
        BAKKES_PID=$!
        log "BakkesMod PID: $BAKKES_PID"

        # Refocus Rocket League after BakkesMod launches
        ${pkgs.coreutils}/bin/sleep 2
        ${pkgs.wmctrl}/bin/wmctrl -a "Rocket League" 2>/dev/null || log "Could not refocus game window"

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

        log "Ready! Waiting for game to exit..."

        # Wait for game to exit using kill -0 (lightweight PID check)
        while kill -0 "$GAME_PID" 2>/dev/null; do
            ${pkgs.coreutils}/bin/sleep 0.5
        done

        log "Game exited, stopping BakkesMod..."
        kill "$BAKKES_PID" 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 0.5
        kill -9 "$BAKKES_PID" 2>/dev/null || true
        log "Session ended"
    ) &

    "$@"
  '';
}
