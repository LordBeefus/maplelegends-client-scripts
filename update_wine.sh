#!/bin/bash
GITHUB_REPO="mmtrt/WINE_AppImage"
dir_client="$(cd "$(dirname "$0")" && pwd)"
DEST="$dir_client/wine.AppImage"
VERSION_FILE="$dir_client/.wine_version"

echo "Checking for wine-staging 11.x updates..."

# Fetch all releases, flatten assets, find the first wine-staging_11.x match
# (releases are returned newest-first by the API)
release_data=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases" | \
    jq -r '[.[] | .tag_name as $tag | .assets[] |
            select(.name | test("wine-staging_11\\.[0-9]+-x86_64\\.AppImage")) |
            {tag: $tag, name: .name, url: .browser_download_url}] | first')

latest_tag=$(echo "$release_data" | jq -r '.tag')
asset_name=$(echo "$release_data" | jq -r '.name')
asset_url=$(echo "$release_data" | jq -r '.url')

if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
    echo "Error: Could not find a wine-staging 11.x release."
    exit 1
fi

echo "Latest wine-staging 11.x: $asset_name (tag: $latest_tag)"

# Check cached version
current_tag=""
[[ -f "$VERSION_FILE" ]] && current_tag=$(<"$VERSION_FILE")

if [[ "$current_tag" == "$latest_tag" && -f "$DEST" ]]; then
    echo "wine.AppImage is already up-to-date ($current_tag)"
    exit 0
fi

echo "Downloading $asset_name..."
curl -fSL --progress-bar -o "$DEST" "$asset_url"
chmod +x "$DEST"
echo "$latest_tag" > "$VERSION_FILE"
echo "Updated wine.AppImage to $asset_name ($latest_tag)"
