#!/usr/bin/env bash
# The Last of Us Part II (Remastered) — Launcher script
set -euo pipefail

export GAME_NAME="ThelastofusiiRM"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TLoUIIRemastered"
export GAME_EXE="$GAME_DIR/tlou-ii.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="The Last of Us Part II"
export GAME_ICON="ThelastofusiiRM.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# --- Proton (verplicht: D3D12 FL 12_0; wined3d levert maar 11_1) ---
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="0"          # repack: geen echte appid; 0 = numerieke compatdata-map
export WINEDEBUG="-all"         # onderdrukt o.a. de niet-fatale SDL3-melding

# GAME_STEAM_RUNTIME bewust NIET gezet: kale proton-run is bewezen; SLR4 niet nodig.
# Geen PROVISION_HOOKS / PRE_LAUNCH_HOOKS (bewezen: verse GE-Proton-prefix volstaat).

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"