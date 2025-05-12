#!/bin/bash
dir_client="$(cd "$(dirname "$0")" && pwd)"
WINEPREFIX="$HOME/maplelegends_prefix" WINEARCH=win32 "$dir_client/wine.AppImage" winecfg
