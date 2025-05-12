#!/bin/bash

# get all the relevant directories
dir_script="$(cd "$(dirname "$0")" && pwd)"

dir_client="$PWD"
dir_ml="$dir_client/MapleLegends"
dir_dll_files="$dir_client/dll_files"
dir_prefix_system32="$HOME/maplelegends_prefix/drive_c/windows/system32"

echo "Creating maplelegends_prefix in $HOME/maplelegends_prefix"

echo $(pwd)
WINEPREFIX="$HOME/maplelegends_prefix" WINEARCH=win32 "$dir_client/wine.AppImage" wineboot
echo "Success"

echo "Updating ws2_32.dll and ws2help.dll"
cp "$dir_dll_files/ws2_32.dll" "$dir_prefix_system32/ws2_32.dll"
cp "$dir_dll_files/ws2help.dll" "$dir_prefix_system32/ws2help.dll"
echo "Success"

echo "Setting to Windows 98"
WINEPREFIX="$HOME/maplelegends_prefix" WINEARCH=win32 "$dir_client/wine.AppImage" regedit "$dir_dll_files/win98.reg"
echo "Success"

echo "Set default 800x600 resolution"
WINEPREFIX="$HOME/maplelegends_prefix" WINEARCH=win32 "$dir_client/wine.AppImage" regedit "$dir_dll_files/non-windowed.reg"
WINEPREFIX="$HOME/maplelegends_prefix" WINEARCH=win32 "$dir_client/wine.AppImage" regedit "$dir_dll_files/window-settings.reg"
echo "Success"