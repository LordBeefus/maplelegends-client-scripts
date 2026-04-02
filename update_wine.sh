#!/bin/bash
set -eo pipefail

dir_client="$(cd "$(dirname "$0")" && pwd)"

# Source configuration
source "$dir_client/config.sh"

GITHUB_REPO="mmtrt/WINE_AppImage"
DEST="$dir_client/wine.AppImage"
VERSION_FILE="$dir_client/.wine_version"
WINE_VERSION="11"

dir_logs="$dir_client/logs"
mkdir -p "$dir_logs"
if [[ -n "${ML_LOG_FILE:-}" ]]; then
    log_file="$ML_LOG_FILE"
else
    log_file="$dir_logs/update_wine-$(date +%Y%m%d_%H%M%S).log"
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

debug "Starting wine updater"
debug "Repository: $GITHUB_REPO"
debug "log_file=$log_file"

echo "Checking for wine-staging $WINE_VERSION.x updates..."

# Fetch all releases, flatten assets, find the first wine-staging_11.x match
# (releases are returned newest-first by the API)
release_data=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases" | \
    jq -r '[.[] | .tag_name as $tag | .assets[] |
            select(.name | test("wine-staging_11\\.[0-9]+-x86_64\\.AppImage")) |
            {tag: $tag, name: .name, url: .browser_download_url}] | first')

debug "Release metadata fetched"

latest_tag=$(echo "$release_data" | jq -r '.tag')
asset_name=$(echo "$release_data" | jq -r '.name')
asset_url=$(echo "$release_data" | jq -r '.url')

if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
    debug "No matching release found"
    echo "Error: Could not find a wine-staging 11.x release."
    exit 1
fi

echo "Latest wine-staging 11.x: $asset_name (tag: $latest_tag)"

# Check cached version
current_tag=""
[[ -f "$VERSION_FILE" ]] && current_tag=$(<"$VERSION_FILE")
debug "Current cached tag: ${current_tag:-<none>}"

if [[ "$current_tag" == "$latest_tag" && -f "$DEST" ]]; then
    debug "wine.AppImage already up to date"
    echo "wine.AppImage is already up-to-date ($current_tag)"
    exit 0
fi

echo "Downloading $asset_name..."
debug "Downloading asset URL: $asset_url"
curl -fSL --progress-bar -o "$DEST" "$asset_url"
chmod +x "$DEST"
echo "$latest_tag" > "$VERSION_FILE"
debug "Updated version file: $VERSION_FILE"
echo "Updated wine.AppImage to $asset_name ($latest_tag)"
