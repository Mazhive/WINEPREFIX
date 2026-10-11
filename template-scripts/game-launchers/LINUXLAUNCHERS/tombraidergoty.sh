#!/usr/bin/env bash
# TombRaiderGOTY — Launcher script
set -euo pipefail

export GAME_NAME="TombRaiderGOTY"
export GAME_DISPLAY_NAME="Tomb Raider: Game of the Year Edition"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TombRaiderGOTYEdition"
export GAME_EXE="$GAME_DIR/TombRaider.exe"
export GAME_ICON="TombRaiderGOTY.png"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Effectieve set uit de referentie (movedprefixes/TombRaiderGOTY/pfx):
# DXVK (d3d11/dxgi/d3d9 native) + DirectX-hulplibs (d3dx9_43 + d3dcompiler_43).
export PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "install_d3dcompiler_43")

source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"