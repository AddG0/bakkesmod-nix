# BakkesMod runtime scripts
#
# Three scripts are generated:
# - bakkes-config-sync: Writes Nix-managed cvars to cfg/nix-config.cfg
# - bakkes-plugin-sync: Copies plugin DLLs and data, manages plugins.cfg
# - bakkes-launcher: Steam launch wrapper that starts BakkesMod with the game
{
  pkgs,
  lib,
  cfg,
  configLib,
  ...
}:
with lib; let
  generateConfigContent = configLib.generateConfigContent cfg;

  generatePluginConfigs = concatMapStringsSep "\n\n" (p:
    optionalString (p.extraConfig != "") ''
      // Plugin: ${p.plugin.pname or "unknown"}
      ${p.extraConfig}''
  ) cfg._normalizedPlugins;

  # Sanitize plugin names for safe shell usage
  validatePluginName = name:
    if builtins.match "^[a-zA-Z0-9_-]+$" name != null
    then name
    else builtins.replaceStrings [" " "'" "\"" "&" "|" ";" "$" "`" "(" ")" "[" "]" "{" "}" "<" ">" "\\"] ["_" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""] name;
in {
  bakkes-config-sync = pkgs.writeShellScriptBin "bakkes-config-sync" ''
    #!/usr/bin/env bash
    set -euo pipefail

    log() { echo "[$(date +%H:%M:%S)] $1"; }

    BAKKES_DATA="$1"

    if [ ! -d "$BAKKES_DATA" ]; then
        log "ERROR: BakkesMod data directory not found: $BAKKES_DATA"
        log "BakkesMod must be launched at least once to create this directory."
        exit 1
    fi

    mkdir -p -m 755 "$BAKKES_DATA/cfg"

    # Write config atomically via temp file
    TMP_CONFIG=$(mktemp) || { log "ERROR: Failed to create temp file"; exit 1; }
    trap "rm -f '$TMP_CONFIG'" EXIT

    cat > "$TMP_CONFIG" << 'EOF'
// Nix-managed BakkesMod configuration
// Generated from Home Manager - do not edit manually
${generateConfigContent}
${generatePluginConfigs}
EOF

    if [ ! -s "$TMP_CONFIG" ]; then
        log "ERROR: Generated config is empty"
        exit 1
    fi

    NIX_CONFIG="$BAKKES_DATA/cfg/nix-config.cfg"
    if ! mv "$TMP_CONFIG" "$NIX_CONFIG"; then
        log "ERROR: Failed to write config"
        exit 1
    fi
    trap - EXIT

    # Ensure autoexec.cfg sources our config (atomic update)
    AUTOEXEC="$BAKKES_DATA/cfg/autoexec.cfg"
    touch "$AUTOEXEC"

    if ! ${pkgs.gnugrep}/bin/grep -qF "exec nix-config.cfg" "$AUTOEXEC" 2>/dev/null; then
        TMP_AUTOEXEC=$(mktemp) || { log "ERROR: Failed to create temp file"; exit 1; }
        if cat "$AUTOEXEC" > "$TMP_AUTOEXEC" && echo "exec nix-config.cfg" >> "$TMP_AUTOEXEC"; then
            mv "$TMP_AUTOEXEC" "$AUTOEXEC"
            log "Added nix-config.cfg to autoexec.cfg"
        else
            rm -f "$TMP_AUTOEXEC"
            log "ERROR: Failed to update autoexec.cfg"
        fi
    fi

    log "Config sync complete"
  '';

  bakkes-plugin-sync = pkgs.writeShellScriptBin "bakkes-plugin-sync" ''
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob

    log() { echo "[$(date +%H:%M:%S)] $1"; }

    BAKKES_DATA="$1"

    if [ ! -d "$BAKKES_DATA" ]; then
        log "ERROR: BakkesMod data directory not found: $BAKKES_DATA"
        exit 1
    fi

    mkdir -p -m 755 "$BAKKES_DATA/plugins"
    mkdir -p -m 755 "$BAKKES_DATA/plugins/settings"
    mkdir -p -m 755 "$BAKKES_DATA/data"

    # Collect wanted plugin names into array
    declare -a WANTED_PLUGINS=()
    ${concatMapStringsSep "\n" (p: let
      safeName = validatePluginName (p.plugin.pname or "unknown");
    in ''
        if [ -d "${p.plugin}/share/bakkesmod" ]; then
            WANTED_PLUGINS+=("${safeName}")
        fi
      '')
      cfg._normalizedPlugins}

    is_plugin_wanted() {
        local check_name="$1"
        for wanted in "''${WANTED_PLUGINS[@]:-}"; do
            [[ "$wanted" == "$check_name" ]] && return 0
        done
        return 1
    }

    # Remove plugins no longer in Nix config (tracked via .nix-managed markers)
    for marker in "$BAKKES_DATA/plugins"/*.nix-managed; do
        PLUGIN_NAME=$(basename "$marker" .nix-managed)

        if [[ ! "$PLUGIN_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log "WARNING: Invalid marker name, skipping: $PLUGIN_NAME"
            continue
        fi

        if ! is_plugin_wanted "$PLUGIN_NAME"; then
            log "Removing plugin: $PLUGIN_NAME"

            while IFS= read -r file || [[ -n "$file" ]]; do
                [[ -z "$file" ]] && continue

                # Update plugins.cfg when removing a DLL
                if [[ "$file" == plugins/*.dll ]]; then
                    DLL_FILE=$(basename "$file")
                    DLL_NAME="''${DLL_FILE%.dll}"
                    DLL_NAME=$(echo "$DLL_NAME" | tr '[:upper:]' '[:lower:]')

                    if [[ "$DLL_NAME" =~ ^[a-zA-Z0-9_-]+$ ]] && [ -f "$BAKKES_DATA/cfg/plugins.cfg" ]; then
                        cp "$BAKKES_DATA/cfg/plugins.cfg" "$BAKKES_DATA/cfg/plugins.cfg.bak"

                        GREP_EXIT=0
                        ${pkgs.gnugrep}/bin/grep -vF "plugin load $DLL_NAME" "$BAKKES_DATA/cfg/plugins.cfg" > "$BAKKES_DATA/cfg/plugins.cfg.tmp" || GREP_EXIT=$?

                        if [ $GREP_EXIT -eq 0 ]; then
                            mv "$BAKKES_DATA/cfg/plugins.cfg.tmp" "$BAKKES_DATA/cfg/plugins.cfg"
                            rm -f "$BAKKES_DATA/cfg/plugins.cfg.bak"
                            log "Disabled $DLL_NAME in plugins.cfg"
                        elif [ $GREP_EXIT -eq 1 ]; then
                            # No match found - line wasn't there
                            rm -f "$BAKKES_DATA/cfg/plugins.cfg.tmp" "$BAKKES_DATA/cfg/plugins.cfg.bak"
                        else
                            log "WARNING: Failed to update plugins.cfg, restoring backup"
                            mv "$BAKKES_DATA/cfg/plugins.cfg.bak" "$BAKKES_DATA/cfg/plugins.cfg"
                            rm -f "$BAKKES_DATA/cfg/plugins.cfg.tmp"
                        fi
                    fi
                fi

                # Validate path before deletion (prevent traversal attacks)
                if [[ "$file" == *".."* ]] || [[ "$file" == /* ]]; then
                    log "WARNING: Suspicious path in marker, skipping: $file"
                    continue
                fi

                rm -f "$BAKKES_DATA/$file" 2>/dev/null || true
            done < "$marker"

            rm -f "$marker"
        fi
    done

    # Install/update plugins from Nix store
    ${concatMapStringsSep "\n" (p: let
      safeName = validatePluginName (p.plugin.pname or "unknown");
    in ''
        if [ -d "${p.plugin}/share/bakkesmod" ]; then
            PLUGIN_NAME="${safeName}"
            MARKER_FILE="$BAKKES_DATA/plugins/$PLUGIN_NAME.nix-managed"

            log "Installing plugin: $PLUGIN_NAME"
            > "$MARKER_FILE"

            # Find DLL name for plugins.cfg entry
            DLL_NAME=""
            if [ -d "${p.plugin}/share/bakkesmod/plugins" ]; then
                DLL_FILE=$(find "${p.plugin}/share/bakkesmod/plugins" -maxdepth 1 -name "*.dll" -printf "%f\n" 2>/dev/null | head -1)
                if [ -n "$DLL_FILE" ]; then
                    DLL_NAME="''${DLL_FILE%.dll}"
                    DLL_NAME=$(echo "$DLL_NAME" | tr '[:upper:]' '[:lower:]')
                fi
            fi

            # Copy plugin files, preserving directory structure
            cd "${p.plugin}/share/bakkesmod"
            find . -type f | while IFS= read -r file; do
                REL_PATH="''${file#./}"

                # Path traversal protection
                if [[ "$REL_PATH" == *".."* ]] || [[ "$REL_PATH" == /* ]]; then
                    log "ERROR: Path traversal in plugin ${safeName}: $REL_PATH"
                    continue
                fi

                FULL_PATH="$BAKKES_DATA/$REL_PATH"
                CANONICAL_PATH=$(${pkgs.coreutils}/bin/realpath -m "$FULL_PATH" 2>/dev/null) || continue
                CANONICAL_BASE=$(${pkgs.coreutils}/bin/realpath -m "$BAKKES_DATA" 2>/dev/null) || continue

                if [[ "$CANONICAL_PATH" != "$CANONICAL_BASE"* ]]; then
                    log "ERROR: Path escapes data directory: $REL_PATH"
                    continue
                fi

                DIR_PATH=$(dirname "$REL_PATH")
                [ "$DIR_PATH" != "." ] && mkdir -p "$BAKKES_DATA/$DIR_PATH"

                # Only copy if newer or missing
                if [ ! -f "$BAKKES_DATA/$REL_PATH" ] || [ "$file" -nt "$BAKKES_DATA/$REL_PATH" ]; then
                    ${pkgs.coreutils}/bin/cp -f "$file" "$BAKKES_DATA/$REL_PATH"
                fi

                echo "$REL_PATH" >> "$MARKER_FILE"
            done

            # Register plugin in plugins.cfg
            if [ -n "$DLL_NAME" ] && [[ "$DLL_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                mkdir -p "$BAKKES_DATA/cfg"
                touch "$BAKKES_DATA/cfg/plugins.cfg"

                if ! ${pkgs.gnugrep}/bin/grep -qF "plugin load $DLL_NAME" "$BAKKES_DATA/cfg/plugins.cfg" 2>/dev/null; then
                    echo "plugin load $DLL_NAME" >> "$BAKKES_DATA/cfg/plugins.cfg"
                    log "Enabled $DLL_NAME in plugins.cfg"
                fi
            fi
        fi
      '')
      cfg._normalizedPlugins}

    log "Plugin sync complete"
  '';

  # Steam launch wrapper: bakkes-launcher %command%
  bakkes-launcher = pkgs.writeShellScriptBin "bakkes-launcher" ''
    #!/usr/bin/env bash
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
        log "Waiting for Rocket League..."

        # Detect actual game process (Wine Z:\ path), not wrappers
        game_running() {
            ${pkgs.procps}/bin/pgrep -f "Z:.*RocketLeague\\.exe" >/dev/null 2>&1
        }

        WAIT_COUNT=0
        while ! game_running; do
            ${pkgs.coreutils}/bin/sleep 0.5
            WAIT_COUNT=$((WAIT_COUNT + 1))
            if [ $WAIT_COUNT -gt 600 ]; then
                log "ERROR: Timeout waiting for game"
                exit 1
            fi
        done

        GAME_PID=$(${pkgs.procps}/bin/pgrep -f "Z:.*RocketLeague\\.exe")
        log "Game detected (PID: $GAME_PID), initializing..."
        BAKKES_DATA="$RL_PREFIX/pfx/drive_c/users/steamuser/AppData/Roaming/bakkesmod/bakkesmod"

        # Sync config/plugins before launching BakkesMod (if data dir exists from previous run)
        if [ -d "$BAKKES_DATA" ]; then
            log "Syncing config and plugins..."
            ${cfg._scripts.bakkes-config-sync}/bin/bakkes-config-sync "$BAKKES_DATA" >> "$BAKKES_LOG" 2>/dev/null || log "ERROR: Config sync failed"
            ${cfg._scripts.bakkes-plugin-sync}/bin/bakkes-plugin-sync "$BAKKES_DATA" >> "$BAKKES_LOG" 2>/dev/null || log "ERROR: Plugin sync failed"
        else
            log "First run - will sync after BakkesMod creates data directory"
        fi

        if ! kill -0 $GAME_PID 2>/dev/null; then
            log "ERROR: Game exited during init"
            exit 1
        fi

        log "Launching BakkesMod..."
        WINEDEBUG=-all WINEFSYNC=1 WINEPREFIX="$RL_PREFIX/pfx" "$PROTON/bin/wine64" ${cfg.package}/bin/BakkesMod.exe 2>/dev/null &
        BAKKES_PID=$!
        log "BakkesMod PID: $BAKKES_PID"

        # On first run, wait for data dir and sync
        if [ ! -d "$BAKKES_DATA" ]; then
            WAIT_COUNT=0
            while [ ! -d "$BAKKES_DATA" ] && [ $WAIT_COUNT -lt 60 ]; do
                kill -0 $BAKKES_PID 2>/dev/null || { log "ERROR: BakkesMod died"; exit 1; }
                ${pkgs.coreutils}/bin/sleep 1
                WAIT_COUNT=$((WAIT_COUNT + 1))
            done

            [ ! -d "$BAKKES_DATA" ] && { log "ERROR: Timeout waiting for data dir"; exit 1; }

            log "Syncing config and plugins..."
            ${cfg._scripts.bakkes-config-sync}/bin/bakkes-config-sync "$BAKKES_DATA" >> "$BAKKES_LOG" 2>/dev/null || log "ERROR: Config sync failed"
            ${cfg._scripts.bakkes-plugin-sync}/bin/bakkes-plugin-sync "$BAKKES_DATA" >> "$BAKKES_LOG" 2>/dev/null || log "ERROR: Plugin sync failed"
        fi

        log "Ready! Waiting for game to exit..."

        # Wait for game to exit using kill -0 (lightweight PID check)
        while kill -0 $GAME_PID 2>/dev/null; do
            ${pkgs.coreutils}/bin/sleep 0.5
        done

        log "Game exited, stopping BakkesMod..."
        kill $BAKKES_PID 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 0.5
        kill -9 $BAKKES_PID 2>/dev/null || true
        log "Session ended"
    ) &

    "$@"
  '';
}
