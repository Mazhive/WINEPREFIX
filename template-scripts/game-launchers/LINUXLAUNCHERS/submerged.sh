#!/usr/bin/env bash
# Submerged — Launcher script
set -euo pipefail

export GAME_NAME="Submerged"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Submerged"
export GAME_EXE="$GAME_DIR/Submerged.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Geen PROVISION_HOOKS, geen PRE_LAUNCH_HOOKS nodig (zie BEVINDINGEN-Submerged.md)

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"