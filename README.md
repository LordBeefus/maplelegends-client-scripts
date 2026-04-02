# Script for unofficial steamdeck MapleLegends Client

The intent with this repo is to focus primarily on getting MapleLegends working on the steamdeck with as little hassle as possible. Although this should work on other Linux PCs, the focus will be on steamdeck.

**DISCLAIMER**
HDClient 2 is not currently supported and is not the objective right now. The objective is getting a minimal working solution first, stretch goals come later.

## Initial setup
- Clone this repo locally
  - Note: ./ is used to represent the repo's base folder
- Ensure the .sh scripts are all executable. (They should already be)
- run ./maplelegends.sh
- OR
- Right click `maplelegends.sh` and click add to steam.
- Launch from steam Gaming mode.

This should do all of the following: Download the wine11 based AppImage, download and unpack the MapleLegends version listed in the config script, create the wine prefix, and finally run maple legends.

The script will try to automatically detect if the steamdeck is in desktop mode vs gaming mode and launch ML in windowed vs fullscreen mode.

I have had success running this for the first time in Gaming mode, but you sit at a black screen for quite a while during the setup process. I suggest you run this first in desktop mode to ensure everything goes well without errors.

If when you launch the game in Gaming mode and you find that you have no mouse cursor try quiting the game > controller settings > set the controls to a mouse and keyboard layout. Then relaunch the game.

### Troubleshooting
- Make sure you are dealing with a clean install if you run into issues. I have provided a helper script `clean.sh` that you can run to remove the wine.AppImage, MapleLegends files, and wine prefix.
- If you still run into issues edit the `config.sh` and set the debug value to true. This will create log files in the `logs/` directory on the next run and we can use that to troubleshoot.

Some things to note:
- ./maplelegends.sh creates the wine prefix in ~/maplelegends_prefix.
- if you need to use winecfg for any reason, you can run ./ml_winecfg.sh
- please run ./maplelegends.sh before ./ml_winecfg.

Acknowledgements:
- https://www.winehq.org
- https://github.com/mmtrt/WINE_AppImage
- https://github.com/doitsujin/dxvk/
- https://maplelegends.com/
- https://github.com/xiujk71 (for creating the original repo and starting the process!)
