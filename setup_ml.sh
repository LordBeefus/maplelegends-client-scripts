#!/bin/bash
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
    filename="gdrive_${FILE_ID}.archive"
    echo "Warning: Could not determine filename, using: $filename"
else
    echo "Filename: $filename"
fi

DEST="$dir_client/$filename"

if [[ -f "$DEST" ]]; then
    echo "File already exists: $DEST"
    read -rp "Re-download and overwrite? [y/N] " confirm
    [[ "$confirm" != [yY] ]] && echo "Skipped." && exit 0
fi

echo "Downloading to $DEST..."
curl -fSL --progress-bar \
    -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
    -o "$DEST" \
    "$DOWNLOAD_URL"

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
        exit 0
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
