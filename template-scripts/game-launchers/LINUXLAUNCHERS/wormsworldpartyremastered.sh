#!/usr/bin/env bash
# Worms World Party Remastered — Launcher script
#
# Start via Proton (GE-Proton11-7), net als Siberia/Ori: de vroege
# wine-aanpak (virtual desktop + DXVK) is vervangen. Het spel staat in
# WINDOWSGAMES/WWP (wwp.exe, 32-bit DirectDraw) met cnc-ddraw als
# scaling-/window-laag (ddraw.dll + ddraw.ini in de gamemap).
# WINEDLLOVERRIDES="ddraw=n,b" zorgt dat cnc-ddraw native laadt — dit
# werkt zowel onder Proton als onder wine.
set -euo pipefail

export GAME_NAME="WormsWorldPartyRemastered"
export GAME_DISPLAY_NAME="Worms World Party Remastered"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/WWP"
export GAME_EXE="$GAME_DIR/wwp.exe"
export GAME_ICON="WormsWorldPartyRemastered.png"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Proton-pad: GE-Proton9-11 11-9 is geprobeert (32-bit loopt via wow64, geen lib32 nodig).
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton9-11"
export STEAM_APPID="0"

# cnc-ddraw (ddraw.dll in de gamemap) moet native laden, niet wine's ddraw.
export WINEDLLOVERRIDES="ddraw=n,b"

# Geen PROVISION_HOOKS: install_dxvk/install_d3dx9 waren winetricks-
# wrappers voor de oude D3D9-build; de huidige build is DirectDraw en
# krijgt beeld/schaling via cnc-ddraw (ddraw.ini). Resolutie-/
# registersleutels (Team17DigitalLTD) zijn in-game instelbaar.

source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"
