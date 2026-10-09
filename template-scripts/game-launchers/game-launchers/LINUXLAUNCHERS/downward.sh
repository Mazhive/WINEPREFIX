#!/bin/bash
# downward.sh — Downward (native Linux-game, UE4.15).
# Roept de originele executable aan; originele Downward.sh blijft ongewijzigd.

export GAME_NAME="Downward"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Downward"
export GAME_NATIVE="1"
# GAME_NATIVE_SHELL niet zetten: direct ELF binary, geen shell-script
export GAME_NATIVE_CMD="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Downward/Downward/Binaries/Linux/Downward"

# Standaard renderer: OpenGL (GUI checkboxes overschrijven via GUI_NATIVE_RENDERER)
export GAME_NATIVE_EXTRA_ARGS="-opengl3"

export GAME_LAUNCHER="$(readlink -f "$0")"
export GAME_DISPLAY_NAME="Downward"
export GAME_ICON="downward.png"

export CREATE_DESKTOP_SHORTCUT="1"
source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"