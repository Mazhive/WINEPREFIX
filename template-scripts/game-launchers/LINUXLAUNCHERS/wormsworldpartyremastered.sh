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

export PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "install_gamescope" "disable_winebus" "install_cnc_ddraw" "install_virtual_desktop" "set_graphics_resolution")

# Gamescope wrapper voor Wayland/AMD fullscreen fixes (zwart scherm/wit vlak fix)
export GAME_GAMESCOPE="1"

# Forceer gamescope resolutie naar scherm resolutie (1920x1080)
export GAME_GAMESCOPE_RES="1920x1080"

# Wine Virtual Desktop instellingen
export WINE_VIRTUAL_DESKTOP="1"
export WINE_DESKTOP_W="1920"
export WINE_DESKTOP_H="1080"

# Laad de centrale core-logica
source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"