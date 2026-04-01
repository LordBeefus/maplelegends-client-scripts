# Script for unofficial MapleLegends Client

To set it up follow steps below:
- Clone this repo locally
  - Note: ./ is used to represent the repo's base folder
- Setup wine appimage
  - run ./update_wine.sh
  - confirm wine.AppImage is in ./
  - If for whatever reason the script does not pull the latest app image you can find it here: https://github.com/mmtrt/WINE_AppImage/releases/tag/test7
  Just make sure you get a version thats based on wine11. At the time of writing the latest is wine-staging_11.1-x86_64.AppImage 
- Setup MapleLegends
  - Download Crossover version of MapleLegends (MAC):
    - Link: https://forum.maplelegends.com/index.php?threads/new-macos-installation-guide-faq.38764/
  - Extract the MapleLegends files
    - In the archive, MapleLegends files are located in MapleLegendsMAC<Release_Date>/drive_c/MapleLegends
    - Extract the folder to ./
    - Check that ./MapleLegends/MapleLegends.exe exist
- Enable executable permissions for these 3 files:
  - ./maplelegends.sh
  - ./ml_winecfg.sh
  - ./update_wine.sh
  - ./wine.AppImage
- Run maplelegends by running ./maplelegends.sh on terminal
- If ./maplelegends.sh doesnt work, run ./maplelegends-windowed.sh

Some things to note:
- ./maplelegends.sh creates the wine prefix in ~/maplelegends_prefix.
- if you need to use winecfg for any reason, you can run ./ml_winecfg.sh
- please run ./maplelegends.sh or ./maplelegends-windowed.sh before ./ml_winecfg.
  - ./maplelegends.sh (and ./maplelegends-windowed.sh) checks if the prefix exist or not and uses that condition to install ws2_32.dll & ws2help.dll

Acknowledgements:
- https://www.winehq.org
- https://github.com/mmtrt/WINE_AppImage
- https://github.com/doitsujin/dxvk/
- https://maplelegends.com/
