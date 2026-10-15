#!/usr/bin/env bash
set -euo pipefail

export GAME_NAME="Siberia1"
export GAME_DISPLAY_NAME="Syberia"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Siberia1"
export GAME_EXE="$GAME_DIR/Syberia.exe"
export GAME_ICON="siberia1.png"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="0"

# Laad de centrale core-logica
source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"