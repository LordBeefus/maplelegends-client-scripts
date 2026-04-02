#!/bin/bash
set -eo pipefail
dir_client="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$dir_client/wine.AppImage" ]]; then
    echo "wine.AppImage not found, running update_wine.sh..."
    bash "$dir_client/update_wine.sh" || { echo "update_wine.sh failed, aborting."; exit 1; }
fi

if [[ ! -d "$dir_client/MapleLegends" ]]; then
    echo "MapleLegends directory not found, running setup_ml.sh..."
    bash "$dir_client/setup_ml.sh" || { echo "setup_ml.sh failed, aborting."; exit 1; }
fi

exec bash "$dir_client/maplelegends-auto.sh"
