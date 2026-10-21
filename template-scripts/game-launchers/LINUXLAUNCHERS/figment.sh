#!/usr/bin/env bash
# Figment — Launcher script (native Linux-game, Unity/GOG-build)
# Zie bevindingen/BEVINDINGEN-Figment.md: native x86_64, geen Wine-prefix.
set -euo pipefail

export GAME_NAME="Figment"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Figment"
export GAME_NATIVE="1"
# Directe ELF-binary (geen shell-wrapper): de GOG-start.sh cd't naar game/,
# maar Unity vindt Figment_Data via het pad van de executable.
export GAME_NATIVE_CMD="game/Figment.x86_64"
export SCRIPT_VERSION="1"
export GAME_LAUNCHER="$(readlink -f "$0")"
export GAME_DISPLAY_NAME="Figment"
export GAME_ICON="Figment.png"

export CREATE_DESKTOP_SHORTCUT="1"

# Geen PROVISION_HOOKS / PRE_LAUNCH_HOOKS: native build, geen Wine en geen
# registry. User-data: ~/.config/unity3d/Bedtime Digital Games/Figment/ en
# ~/My Games/Figment/ (Player.log aldaar bij crashdiagnose).

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
