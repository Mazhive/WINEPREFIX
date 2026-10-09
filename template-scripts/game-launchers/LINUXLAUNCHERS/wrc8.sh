#!/bin/bash
# WRC 8 — Wine launcher via game-common.sh core
# DirectX 11/12 game, 64-bit, requires vcrun2015, vcrun2022, d3dcompiler_47, dxvk

export GAME_NAME="WRC8"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/WRC8"
export GAME_EXE="$GAME_DIR/WRC8.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="WRC 8"
export GAME_ICON="wrc8.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# Wine configuratie
export WINEDEBUG="-all"
export DXVK_HUD="fps,msgs"
export VKD3D_SHADER_CACHE_SIZE="4"

# Gamescope optioneel (standaard uit, GUI checkbox kan aanzetten)
export GAME_GAMESCOPE="0"

# Provision hooks (bij eerste run: prefix setup) — gebruik COMMON hooks
PROVISION_HOOKS=("install_dxvk" "install_vcrun2015" "install_vcrun2022" "install_d3dcompiler_47")

# Pre-launch hooks (bij ELKE start) — disable_winebus voor toetsenbord fix
PRE_LAUNCH_HOOKS=("disable_winebus")

# --- Core laden ---
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
