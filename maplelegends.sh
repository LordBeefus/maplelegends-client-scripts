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
    log_file="$dir_logs/maplelegends-$(date +%Y%m%d_%H%M%S).log"
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

is_gui_launch() {
    [[ ! -t 1 ]]
}

progress_fd=""
progress_pid=""

start_progress_window() {
    if is_gui_launch && command -v zenity >/dev/null 2>&1; then
        coproc ML_PROGRESS {
            zenity --progress \
                --title="MapleLegends Launcher" \
                --text="Starting launcher..." \
                --pulsate \
                --no-cancel \
                --auto-close
        }
        progress_fd="${ML_PROGRESS[1]}"
        progress_pid="$ML_PROGRESS_PID"
    fi
}

stop_progress_window() {
    if [[ -n "$progress_fd" ]]; then
        exec {progress_fd}>&- 2>/dev/null || true
        progress_fd=""
    fi
    if [[ -n "$progress_pid" ]]; then
        wait "$progress_pid" 2>/dev/null || true
        progress_pid=""
    fi
}

status() {
    local msg="$1"
    echo "$msg"

    if [[ -n "$progress_fd" ]]; then
        printf '# %s\n' "$msg" >&"$progress_fd" 2>/dev/null || true
    fi
}

start_progress_window
trap stop_progress_window EXIT

debug "Starting launcher script"
debug "dir_client=$dir_client"
debug "log_file=$log_file"
status "Starting launcher..."

if [[ ! -f "$dir_client/wine.AppImage" ]]; then
    debug "wine.AppImage missing; calling update_wine.sh"
    status "wine.AppImage not found. Downloading wine..."
    bash "$dir_client/update_wine.sh" || { status "Update failed. Aborting."; exit 1; }
fi

if [[ ! -d "$dir_client/MapleLegends" ]]; then
    debug "MapleLegends directory missing; calling setup_ml.sh"
    status "MapleLegends files not found. Running setup..."
    bash "$dir_client/setup_ml.sh" || { status "Setup failed. Aborting."; exit 1; }
fi

debug "Handing off to maplelegends-auto.sh"
stop_progress_window
exec bash "$dir_client/maplelegends-auto.sh"
