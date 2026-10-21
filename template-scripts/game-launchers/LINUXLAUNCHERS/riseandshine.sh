#!/usr/bin/env bash
# Rise & Shine — Launcher script (native Linux-game, Unity 5.4.2f2)
# Zie bevindingen/BEVINDINGEN-RiseAndShine.md voor het volledige analyse- en
# actieplan (padkeuze §5.2, icoon §6, Steam-fix §7.4).
set -euo pipefail

export GAME_NAME="RiseAndShine"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Rise_and_Shine_Linux-ACTIVATED/Rise.and.Shine"
export GAME_NATIVE="1"
# GAME_NATIVE_SHELL niet zetten: directe ELF-binary, geen shell-script.
export GAME_NATIVE_CMD="RiseAndShine.x86_64"
export SCRIPT_VERSION="1"
export GAME_LAUNCHER="$(readlink -f "$0")"
export GAME_DISPLAY_NAME="Rise & Shine"
export GAME_ICON="RiseAndShine.png"

export CREATE_DESKTOP_SHORTCUT="1"

# Geen PROVISION_HOOKS / PRE_LAUNCH_HOOKS: native build, geen Wine-prefix en
# geen registry. De ACTiVATED Steam-emulator hoort in de gamemap zelf
# (activated.ini naast RiseAndShine_Data/Plugins/x86_64/libsteam_api.so).

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

# Exit-code 139 = het spel sluit af met een SEGFAULT ín de ACTiVATED
# steam-emulator (atexit-handler, libsteam_api.so+0x1be39) — pre-existing en
# identiek aan de run vóór deze launcher (zie BEVINDINGEN-RiseAndShine.md §9).
# Zelfs bij een normale quit via het menu; onder `set -e` geeft dat 139 terug
# en toont game-gui.py (regel 860) "Game start mislukt"-popup bij élke sluiting.
# Alleen die exit-code wordt geneutraliseerd — echte startfouten blijven staan.
rc=0
game_main "$@" || rc=$?
if [ "$rc" -eq 139 ]; then
  exit 0
fi
exit "$rc"
