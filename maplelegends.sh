#!/bin/bash
dir_client=$(dirname $(realpath $0))
dir_scripts=$dir_client/scripts
dir_ml=$dir_client/MapleLegends
dir_dll_files=$dir_client/dll_files
dir_prefix_system32=$HOME/maplelegends_prefix/drive_c/windows/system32

echo $dir_prefix_system32
if [[ -d "$dir_prefix_system32" ]]; then
    echo "maplelegends_prefix found"
    
else
    echo "maplelegends_prefix not found"
    
    # Launch prefix_setup script
    $dir_scripts/prefix_setup.sh

fi
echo "Disabling Virtual Desktop"
WINEPREFIX="$HOME/maplelegends_prefix" WINEARCH=win32 $dir_client/wine.AppImage regedit ./dll_files/non-windowed.reg
echo "Starting MapleLegends"
cd "$dir_ml"
WINEPREFIX="$HOME/maplelegends_prefix" WINEARCH=win32 $dir_client/wine.AppImage ./MapleLegends.exe
