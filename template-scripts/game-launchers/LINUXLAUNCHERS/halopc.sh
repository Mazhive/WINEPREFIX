#!/usr/bin/env bash
# Halo: Combat Evolved (PC, origineel) — dunne per-game launcher.
# Zie game-core/game-common.sh voor de logica; hier staat alleen de config.
#
# ── Recept (BEVINDINGEN-HaloPC.md, 2026-10-16) ─────────────────────────
# Halo PC v1.07 (no-CD) draait op een schone win32-prefix (Wine 11.0).
# De referentie-prefix (/home/peter/GAMEPREFIXES/HALO-PC-origineel) had
# winetricks d3dx9/d3dcompiler_43/47/vcrun2005, maar loaddll-bewijs toont
# dat géén van deze componenten wordt geladen. Het spel laadt zijn eigen
# DLL's (binkw32, vorbis, keystone, ...) en Wine builtins (d3d9, ddraw,
# dinput8, dsound, wined3d, ...). DXVK is niet nodig.
# Startargumenten: -vidmode 1920,1080,60 -windowed (cwd = game-dir).
#
# Halo: Combat Evolved (PC, origineel) — dunne per-game launcher.
# Zie game-core/game-common.sh voor de logica; hier staat alleen de config.
#
# ── Recept (BEVINDINGEN-HaloPC.md, 2026-10-16) ─────────────────────────
# Halo PC v1.07 (no-CD) draait op een schone win32/win64-prefix.
# Modern WoW64 vereist PREFIX_ARCH="win64" om 32-bit exe's zonder lib32-pakketten
# op te vangen.
set -euo pipefail

export GAME_NAME="HaloPC"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Halo-PC"
export GAME_EXE="$GAME_DIR/halo.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Halo: Combat Evolved"
export GAME_ICON="halo.png"
export GAME_LAUNCHER="$(readlink -f "$0")"

PRE_PROVISION_HOOKS=("install_wine32")

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

game_main "$@" -vidmode 1920,1080,60 -windowed
