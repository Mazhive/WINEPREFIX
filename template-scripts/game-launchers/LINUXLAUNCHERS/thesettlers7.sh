#!/usr/bin/env bash
# The Settlers 7: Paths to a Kingdom — Launcher script (Vision 9, D3D9, 32-bit).
# Zie game-core/game-common.sh voor de logica; hier staat alleen de config.
#
# ── Bevindingen (2026-10, uit BEVINDINGEN-TheSettlers7.md) ──────────────────
# Game: Ubisoft/Blue Byte 2010, versie 1.2.1221, Vision 9 engine, D3D9, PE32 (32-bit).
# Exe: Settlers7R.exe (Data/Base/_Dbg/Bin/Release/) — NIET de bootstrapper The_Settlers7.exe.
# Crack: 1911.dll vervangt ubiorbitapi_r2.dll → fake Orbit-sessie ("Logged in as: Pirate").
#        Geen Uplay-account nodig voor singleplayer tot menu-map.
# Crash: NULL-deref in Settlers7R.exe+0x5A5D48 (mov eax,[edi], EDI=0) bij laden
#        menu-map Maps/Menu/Castle_Forge_Map, na OnFirstFrame, 295/300.
# Getest met plain Wine: DXVK (Run A) + vcrun2008 (Run B) → crash verplaatst naar
#        ntdll.dll 0x7b675cef (consistent over alle configs). Harde blocker.
# Nu: **Proton (GE-Proton, win32)** testen — §8.5: "test Proton pas daarna, los".
# Prefix: win32 (PE32), Windows 7.
# Icoon: Settlers7.png (306 KB, 512+ px) uit game-root → gameicons/TheSettlers7.png.
set -euo pipefail

export GAME_NAME="TheSettlers7"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/The.Settlers7"
export GAME_EXE="$GAME_DIR/Data/Base/_Dbg/Bin/Release/Settlers7R.exe"
export PREFIX_ARCH="win32"
export SCRIPT_VERSION="2"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="The Settlers 7"
export GAME_ICON="TheSettlers7.png"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Proton runner (GE-Proton11-7 met betere 32-bit DXVK support):
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
# Geen Steam AppID (non-Steam game):
export STEAM_APPID="0"

# Forceer DXVK in Proton (plain Proton gebruikt wined3d):
export PROTON_USE_DXVK="1"
export DXVK_HUD="1"

# Proton logging voor stille exit na intro's:
export PROTON_LOG="1"

# Gamescope wrapper ( vaste resolutie 1024x768, bypass Wayland/XWayland issues):
export GAME_GAMESCOPE="1"
export GAME_GAMESCOPE_RES="1024x768"

# VC++ 2008 runtime via Proton's eigen prefix-upgrade.
# DXVK nu actief via PROTON_USE_DXVK=1.

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"

# GUI environment variables worden automatisch overgedragen door game-common.sh.
# De Python-GUI (game-gui.py) stelt GUI_*-variabelen in (bijv. GUI_MANGOHUD,
# GUI_GAMESCOPE, GUI_VKBASALT, GUI_SDL3_DYNAMIC_API_OFF, GUI_GAMEPAD, etc.).
# Deze worden geëxporteerd in de wine-prefix, ook als de launcher-script eigen
# exports na het sourcen van game-common.sh worden gedefinieerd. Zie
# game-core/game-common.sh voor de forwarding-mechaniek.