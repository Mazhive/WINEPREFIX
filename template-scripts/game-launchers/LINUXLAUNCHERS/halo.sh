#!/bin/bash
# Halo Combat Evolved — Wine launcher via game-common.sh core
# 32-bit, DirectPlay, DXVK, vcrun2008, hardware check bypass

export GAME_NAME="Halo"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Halo"
export GAME_EXE="$GAME_DIR/haloce-patch-1.0.10.exe"
export PREFIX_ARCH="win32"
export SCRIPT_VERSION="6"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Halo Combat Evolved"
export GAME_ICON="halo.png"

export GAME_LAUNCHER="$(readlink -f "$0")"
export WINEDEBUG="-all"
# export DXVK_HUD="fps,msgs"
export GAME_GAMESCOPE="0"

PROVISION_HOOKS=(
    "install_dxvk"
    "install_d3dx9"
    "install_vcrun2008"
    "install_directplay"
    "install_halo_directx"
    "install_halo_directx_reg"
    "install_halo_dlloverrides"
    "install_halo_winver_xp"
)

PRE_LAUNCH_HOOKS=()

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main -vidmode 1360,768,60 -NOVIDEO "$@"
