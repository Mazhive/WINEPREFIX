#!/usr/bin/env bash
# witcher3rm.sh — The Witcher 3: Wild Hunt (GOTY) via Proton + Steam Linux Runtime.
#
# GE-Proton11-7 verklaart in zijn toolmanifest require_tool_appid 4183110
# (= SteamLinuxRuntime_4). Steam start zulke games nooit kaal, maar altijd via
# de runtime-container. De host heeft geen libSDL3.so.0; alleen de SLR4-container
# levert die. Een kale `proton run` faalt daarom met "Failed loading SDL3
# library." en de game sluit direct af. GAME_STEAM_RUNTIME=1 laat game_launch
# de bewezen wrapper gebruiken:
#   <SLR4>/_v2-entry-point --verb=run -- <proton> run <exe>
# De game verwacht zijn werkmap in bin/x64_dx12 (GAME_WORKDIR).
set -euo pipefail

export GAME_NAME="Witcher3RM"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TheWitcher3WildHuntGOTY"
export GAME_EXE="$GAME_DIR/bin/x64_dx12/witcher3.exe"
export GAME_WORKDIR="$GAME_DIR/bin/x64_dx12"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="The Witcher 3: Wild Hunt"
export GAME_ICON="Witcher3RM.png"

export GAME_LAUNCHER="$(readlink -f "$0")"
export PROTON_ENABLED="1"
# Echte Steam-appid van The Witcher 3 (GOG-build); nodig zodat ProtonFixes de
# game kan herkennen.
export STEAM_APPID="1495134320"
# Bewezen werkend voor deze game; als deze ontbreekt valt _detect_proton terug
# op de hoogste GE-Proton / Steam-Proton / umu-run.
export PROTON_PIN="GE-Proton11-7"
# SLR4-wrapper: verplicht voor deze runner (require_tool_appid 4183110).
export GAME_STEAM_RUNTIME="1"

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"
