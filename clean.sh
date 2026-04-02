#!/bin/bash
set -eo pipefail
dir_client="$(cd "$(dirname "$0")" && pwd)"

# Source configuration
source "$dir_client/config.sh"

is_gui_launch() {
    [[ ! -t 1 ]]
}

confirm_cleanup() {
    local msg="This will delete:
- wine.AppImage
- MapleLegends/ directory
- $WINE_PREFIX_DIR

Continue?"

    if is_gui_launch && command -v zenity >/dev/null 2>&1; then
        zenity --question --title="MapleLegends Cleanup" --text="$msg" 2>/dev/null
    else
        echo "$msg"
        read -p "Type 'yes' to confirm: " response
        [[ "$response" == "yes" ]]
    fi
}

cleanup() {
    echo "Cleaning up MapleLegends installation..."
    
    if [[ -f "$dir_client/wine.AppImage" ]]; then
        echo "Removing wine.AppImage..."
        rm -f "$dir_client/wine.AppImage"
    fi
    
    if [[ -d "$dir_client/MapleLegends" ]]; then
        echo "Removing MapleLegends directory..."
        rm -rf "$dir_client/MapleLegends"
    fi
    
    if [[ -d "$WINE_PREFIX_DIR" ]]; then
        echo "Removing wine prefix at $WINE_PREFIX_DIR..."
        rm -rf "$WINE_PREFIX_DIR"
    fi
    
    echo "Cleanup complete."
}

if confirm_cleanup; then
    cleanup
else
    echo "Cleanup cancelled."
    exit 0
fi
