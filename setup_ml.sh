#!/bin/bash
set -eo pipefail

dir_client="$(cd "$(dirname "$0")" && pwd)"

# Source configuration
source "$dir_client/config.sh"

DOWNLOAD_URL="$ML_DOWNLOAD_URL"
COOKIE_FILE="/tmp/gdrive_$$_cookies.txt"

dir_logs="$dir_client/logs"
mkdir -p "$dir_logs"
if [[ -n "${ML_LOG_FILE:-}" ]]; then
    log_file="$ML_LOG_FILE"
else
    log_file="$dir_logs/setup_ml-$(date +%Y%m%d_%H%M%S).log"
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

debug "Starting setup script"
debug "Download URL configured"
debug "log_file=$log_file"

cleanup() { rm -f "$COOKIE_FILE"; }
trap cleanup EXIT

echo "Fetching file info from Google Drive..."

# HEAD request to resolve filename from Content-Disposition and prime cookies
filename=$(curl -fsSL \
    -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
    --head "$ML_DOWNLOAD_URL" | \
    grep -i 'content-disposition' | \
    grep -oP 'filename="?\K[^";\r\n]+' | head -1)

debug "Resolved filename: ${filename:-<empty>}"

if [[ -z "$filename" ]]; then
    echo "Error: Could not determine filename from Google Drive response."
    exit 1
else
    echo "Filename: $filename"
fi

DEST="$dir_client/$filename"

if [[ -f "$DEST" ]]; then
    debug "Destination already exists: $DEST"
    echo "File already exists: $DEST"
    exit 0
fi

echo "Downloading to $DEST..."
if ! curl -fSL --progress-bar \
    -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
    -o "$DEST" \
    "$ML_DOWNLOAD_URL"; then
    echo "Error: Failed to download from Google Drive."
    echo "Cause may be temporary network issues or Google Drive rate limits/quota."
    exit 1
fi

debug "Download complete: $DEST"

# Google Drive may return an HTML error page with HTTP 200 when quota is exceeded.
if grep -qiE "quota exceeded|too many users have viewed or downloaded|download quota" "$DEST"; then
    echo "Error: Google Drive download quota/rate limit reached for this file."
    echo "Please wait and try again later."
    rm -f "$DEST"
    exit 1
fi

echo "Done: $DEST"

# Extract archive to tmp/
TMP_DIR="$dir_client/tmp"
mkdir -p "$TMP_DIR"

echo "Extracting $filename to $TMP_DIR..."
debug "Beginning extraction"
case "$filename" in
    *.tar.gz|*.tgz)   tar -xzf "$DEST" -C "$TMP_DIR" ;;
    *.tar.bz2|*.tbz2) tar -xjf "$DEST" -C "$TMP_DIR" ;;
    *.tar.xz)          tar -xJf "$DEST" -C "$TMP_DIR" ;;
    *.tar)             tar -xf  "$DEST" -C "$TMP_DIR" ;;
    *.zip)             unzip -o  "$DEST" -d "$TMP_DIR" ;;
    *.cxarchive)       tar -xzf "$DEST" -C "$TMP_DIR" ;;
    *.7z)              7z x      "$DEST" -o"$TMP_DIR" ;;
    *.rar)             unrar x   "$DEST"  "$TMP_DIR/" ;;
    *)
        debug "Unsupported archive extension: $filename"
        echo "Warning: Unknown archive type for '$filename', skipping extraction."
        exit 1
        ;;
esac

echo "Extracted to: $TMP_DIR"

# Move MapleLegends folder from extracted bottle to project root
version_name="${filename%.cxarchive}"
ML_SRC="$TMP_DIR/$version_name/drive_c/MapleLegends"

if [[ ! -d "$ML_SRC" ]]; then
    debug "Expected source directory not found: $ML_SRC"
    echo "Error: Expected folder not found: $ML_SRC"
    exit 1
fi

ML_DEST="$dir_client/MapleLegends"

if [[ -d "$ML_DEST" ]]; then
    debug "Destination already exists and may be overwritten: $ML_DEST"
    echo "MapleLegends already exists at $ML_DEST"
    read -rp "Overwrite? [y/N] " confirm
    [[ "$confirm" != [yY] ]] && echo "Skipped move." && exit 0
    rm -rf "$ML_DEST"
fi

mv "$ML_SRC" "$ML_DEST"
echo "Moved MapleLegends to: $ML_DEST"

# Cleanup
echo "Cleaning up..."
debug "Removing downloaded archive and temp directory"
rm -f "$DEST"
rm -rf "$TMP_DIR"
echo "Cleanup complete."
