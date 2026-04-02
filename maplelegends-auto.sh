#!/bin/bash
set -eo pipefail

dir_client="$(cd "$(dirname "$0")" && pwd)"

# Source configuration
source "$dir_client/config.sh"
dir_scripts=$dir_client/scripts
dir_ml=$dir_client/MapleLegends
dir_prefix=$WINE_PREFIX_DIR
dir_prefix_system32=$dir_prefix/drive_c/windows/system32
dir_logs=$dir_client/logs

mkdir -p "$dir_logs"
if [[ -n "${ML_LOG_FILE:-}" ]]; then
    log_file="$ML_LOG_FILE"
else
    log_file="$dir_logs/maplelegends-auto-$(date +%Y%m%d_%H%M%S).log"
    export ML_LOG_FILE="$log_file"
fi

if [[ "$DEBUG" == "true" && "${ML_LOG_REDIRECTED:-0}" != "1" ]]; then
    export ML_LOG_REDIRECTED=1
    exec > >(tee -a "$log_file") 2>&1
fi

log() {
    if [[ "$DEBUG" == "true" ]]; then
        printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$(basename "$0")" "$1"
    fi
}

log "Script start"
log "log_file=$log_file"
log "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<unset>}"

echo "dir_prefix_system32: $dir_prefix_system32"
if [[ -d "$dir_prefix_system32" ]]; then
    echo "maplelegends_prefix found"
    
else
    echo "maplelegends_prefix not found"
    echo "dir_client: $dir_client"

    # Launch prefix_setup script
    echo "Start: Creating maplelegends_prefix in $dir_prefix"
    WINEPREFIX="$dir_prefix" "$dir_client/wine.AppImage" wineboot
    echo "End: Creating maplelegends_prefix in $HOME/maplelegends_prefix"

    echo "Start: Setting to Windows 98"
    WINEPREFIX="$WINE_PREFIX_DIR" "$dir_client/wine.AppImage" winecfg -v win98
    echo "End: Setting to Windows 98"

fi

# Detect session type
if [[ "${SteamGamepadUI}" == "1" ]] || [[ "${XDG_CURRENT_DESKTOP}" == "gamescope" ]]; then
    log "Session mode detected: gaming (SteamGamepadUI=${SteamGamepadUI}, XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP})"
    SESSION_MODE="gaming"
else
    log "Session mode detected: windowed (SteamGamepadUI=${SteamGamepadUI}, XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP})"
    SESSION_MODE="windowed"
fi

cd "$dir_ml"

if [[ "$SESSION_MODE" == "windowed" ]]; then
    log "Entering windowed control flow"
    # Windowed Mode
    # Get Window Size
    legends_ini=$(<"$dir_ml/Legends.ini")
    HDClient=800x600

    if [[ "$legends_ini" == *"HDClient = 1"* ]]; then
        HDClient=1024x768
    elif [[ "$legends_ini" == *"HDClient = 2"* ]]; then
        HDClient=1366x768
    fi

    log "HDClient resolution selected: $HDClient"

    # Generate unique string
    random_string=$(openssl rand -base64 6)

    log "Launching windowed client"
    WINEPREFIX="$dir_prefix" "$dir_client/wine.AppImage" explorer /desktop=Desktop-#$random_string,$HDClient maplelegends.exe
else
    # Gaming Mode (Fullscreen)
    log "Entering gaming control flow"
    log "Launching fullscreen client"
    WINEPREFIX="$dir_prefix" "$dir_client/wine.AppImage" "$dir_ml/MapleLegends.exe" DXVK_HUD=1
fi
