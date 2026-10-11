#!/usr/bin/env bash
# Shadow of the Tomb Raider — Launcher script
set -euo pipefail

export GAME_NAME="SOTTR"
export GAME_DISPLAY_NAME="Shadow of the Tomb Raider"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Tombraider.SOTTR"
export GAME_EXE="$GAME_DIR/SOTTR.exe"
export GAME_ICON="sottr.png"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="750920"

# Optionele hooks (uitschakelen indien niet nodig)
# export PROVISION_HOOKS=("install_vcrun2019")

# Pre-launch hooks (bij elke start): DXR-detectie (nodxr op niet-RT GPU's) +
# vkd3d-shader-cache naar de lokale prefix i.p.v. de NFS-gamefolder.
PRE_LAUNCH_HOOKS=("gpu_dxr_detect" "vkd3d_cache_prefix")

# Laad de centrale core-logica
source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"