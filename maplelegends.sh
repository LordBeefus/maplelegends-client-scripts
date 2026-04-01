#!/bin/bash
dir_client="$(cd "$(dirname "$0")" && pwd)"
dir_scripts=$dir_client/scripts
dir_ml=$dir_client/MapleLegends
dir_prefix=$HOME/maplelegends_prefix
dir_prefix_system32=$HOME/maplelegends_prefix/drive_c/windows/system32

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
    WINEPREFIX="$HOME/maplelegends_prefix" "$dir_client/wine.AppImage" winecfg -v win98
    echo "End: Setting to Windows 98"

fi
echo "Starting MapleLegends"
cd "$dir_ml"
WINEPREFIX="$dir_prefix" "$dir_client/wine.AppImage" "$dir_ml/MapleLegends.exe" DXVK_HUD=1
