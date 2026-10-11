#!/usr/bin/env bash
# Worms World Party Remastered — Launcher script
set -euo pipefail

export GAME_NAME="WormsWorldPartyRemastered"
export GAME_DISPLAY_NAME="Worms World Party Remastered"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/WormsWorldPartyRemastered"
export GAME_EXE="$GAME_DIR/w2.exe"
export GAME_ICON="WormsWorldPartyRemastered.png"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

export PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "disable_winebus" "set_graphics_resolution")

# DXVK instellingen (dwing venstermodus + schakel VSync uit)
export DXVK_WND_FORCE_ALPHA="1"
export DXVK_CONFIG="d3d9.forceWindowed=True; d3d9.presentInterval=0; d3d9.shaderModel=1"

# DirectDraw wrapper inschakelen
export WINEDLLOVERRIDES="ddraw=n,b"

# Wine Virtual Desktop AAN: forceert windowed mode (1024x768), omzeilt fullscreen-moduswissel op Wayland.
# KWin schaalt het venster naar fullscreen. Geen gamescope nodig.
export GAME_GAMESCOPE="0"
export WINE_VIRTUAL_DESKTOP="1"
export WINE_DESKTOP_W="1024"
export WINE_DESKTOP_H="768"

source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"
