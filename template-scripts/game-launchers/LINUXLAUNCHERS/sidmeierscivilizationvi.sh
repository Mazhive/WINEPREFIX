#!/usr/bin/env bash
# Sid Meier's Civilization VI — Launcher script (native Linux-game, Aspyr-build)
# Zie bevindingen/BEVINDINGEN-SidMeiersCivilizationVI.md: native x86_64 ELF,
# geen Wine-prefix, geen register. Startcommando: Civ6.
set -euo pipefail

export GAME_NAME="SidMeiersCivilizationVI"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Sid.Meiers.Civilization.VI"
export GAME_NATIVE="1"
# Directe ELF-binary (geen shell-wrapper): de game laadt zijn .so's en
# aspyrassets/steamassets via het pad van de executable.
export GAME_NATIVE_CMD="Civ6"
export SCRIPT_VERSION="1"
export GAME_LAUNCHER="$(readlink -f "$0")"
export GAME_DISPLAY_NAME="Sid Meier's Civilization VI"
export GAME_ICON="SidMeiersCivilizationVI.png"

export CREATE_DESKTOP_SHORTCUT="1"

# Geen PROVISION_HOOKS / PRE_LAUNCH_HOOKS: native build, geen Wine en geen
# registry. User-data: ~/.local/share/aspyr-media/Sid Meier's Civilization VI/
# (Logs/ en Saves/ aldaar bij crashdiagnose).

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
