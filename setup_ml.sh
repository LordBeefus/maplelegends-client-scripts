#!/bin/bash
set -eo pipefail
FILE_ID="112hrk8whGO_nuy49aJbr8tJcgkqnjmxy"
DOWNLOAD_URL="https://drive.usercontent.google.com/download?id=${FILE_ID}&export=download&confirm=t"
dir_client="$(cd "$(dirname "$0")" && pwd)"
COOKIE_FILE="/tmp/gdrive_$$_cookies.txt"

cleanup() { rm -f "$COOKIE_FILE"; }
trap cleanup EXIT

echo "Fetching file info from Google Drive..."

# HEAD request to resolve filename from Content-Disposition and prime cookies
filename=$(curl -fsSL \
    -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
    --head "$DOWNLOAD_URL" | \
    grep -i 'content-disposition' | \
    grep -oP 'filename="?\K[^";\r\n]+' | head -1)

if [[ -z "$filename" ]]; then
    echo "Error: Could not determine filename from Google Drive response."
    exit 1
else
    echo "Filename: $filename"
fi

DEST="$dir_client/$filename"

if [[ -f "$DEST" ]]; then
    echo "File already exists: $DEST"
    exit 0
fi

echo "Downloading to $DEST..."
if ! curl -fSL --progress-bar \
    -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
    -o "$DEST" \
    "$DOWNLOAD_URL"; then
    echo "Error: Failed to download from Google Drive."
    echo "Cause may be temporary network issues or Google Drive rate limits/quota."
    exit 1
fi

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
        echo "Warning: Unknown archive type for '$filename', skipping extraction."
        exit 1
        ;;
esac

echo "Extracted to: $TMP_DIR"

# Move MapleLegends folder from extracted bottle to project root
version_name="${filename%.cxarchive}"
ML_SRC="$TMP_DIR/$version_name/drive_c/MapleLegends"

if [[ ! -d "$ML_SRC" ]]; then
    echo "Error: Expected folder not found: $ML_SRC"
    exit 1
fi

ML_DEST="$dir_client/MapleLegends"

if [[ -d "$ML_DEST" ]]; then
    echo "MapleLegends already exists at $ML_DEST"
    read -rp "Overwrite? [y/N] " confirm
    [[ "$confirm" != [yY] ]] && echo "Skipped move." && exit 0
    rm -rf "$ML_DEST"
fi

mv "$ML_SRC" "$ML_DEST"
echo "Moved MapleLegends to: $ML_DEST"

# Cleanup
echo "Cleaning up..."
rm -f "$DEST"
rm -rf "$TMP_DIR"
echo "Cleanup complete."
