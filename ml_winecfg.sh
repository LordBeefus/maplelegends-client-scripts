#!/bin/bash
set -eo pipefail

dir_client="$(cd "$(dirname "$0")" && pwd)"

# Source configuration
source "$dir_client/config.sh"

dir_logs="$dir_client/logs"
mkdir -p "$dir_logs"
if [[ -n "${ML_LOG_FILE:-}" ]]; then
    log_file="$ML_LOG_FILE"
else
    log_file="$dir_logs/ml_winecfg-$(date +%Y%m%d_%H%M%S).log"
    export ML_LOG_FILE="$log_file"
fi

if [[ "$DEBUG" == "true" && "${ML_LOG_REDIRECTED:-0}" != "1" ]]; then
	export ML_LOG_REDIRECTED=1
	exec > >(tee -a "$log_file") 2>&1
fi

debug() {
	if [[ "$DEBUG" == "true" ]]; then
		printf '[DEBUG] [%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$(basename "$0")" "$1"
	fi
}

debug "Launching winecfg"
debug "WINEPREFIX=$WINE_PREFIX_DIR"
debug "log_file=$log_file"

WINEPREFIX="$WINE_PREFIX_DIR" WINEARCH=win32 "$dir_client/wine.AppImage" winecfg
