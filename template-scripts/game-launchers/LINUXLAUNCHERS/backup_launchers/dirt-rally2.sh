#!/bin/bash
# DiRT Rally 2 (CODEX) — Plain Wine launcher via game-common.sh core
# Unity-titel, CODEX Steam-emulator (CrashSender1405.exe), Steam appid 690790.
# Kale Wine; GE-Proton niet nodig (de bewezen startregel is wine64 zonder Proton).
#
# De prefix wordt ALTIJD vers opgebouwd (wineboot -i, zie game-common.sh
# regel ~60): er wordt nooit een bestaande prefix gekopieerd of vanaf de
# NFS-share gebruikt. Verwijder je $GAMEPREFIXES_ROOT/DirtRally2, dan maakt
# deze launcher hem gewoon opnieuw aan — dat is de beproefde weg om te
# controleren of de provisioning reproduceerbaar is.
#
# Nulmeting VC++2019: de referentie-prefix (movedprefixes/690790) bevat alle
# acht vereiste DLL's in plausibele grootte (ucrtbase.dll 3,7 MB); een verse
# `wineboot -i` heeft die niet. Verdere hooks pas toevoegen als een
# opstarttest dat afdwingt (werkwijze van chaosengine.sh / crysis.sh).
#
# DXVK: de eerste start gaf WineD3D-beeld zonder schaal (venster linksboven,
# zwarte randen onder en rechts). Op deze AMD Radeon RX 7600 XT (RADV) draait
# DXVK over Vulkan; winetricks zet d3d11/dxgi op native.
#
# GEEN set -euo pipefail: bewust omhooggelaten ten opzichte van anno1800.sh.
# De CODEX-referentie automationempire.sh (eveneens CODEX + kale Wine) doet dit
# ook, en `set -e` rond een gesourced core kan afbreken op een onschuldige
# non-zero exit van een helper.

# --- Basisinstellingen (ALLE exports VOOR sourcing game-common.sh) ---
export GAME_NAME="DirtRally2"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/DiRT_Rally_2"
export GAME_EXE="$GAME_DIR/dirtrally2.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="2"   # bump = bewuste herbouw; nodig toen DXVK erbij kwam
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="DiRT Rally 2"
export GAME_ICON="DirtRally2.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

export STEAM_APPID="690790" # DiRT Rally 2 Steam appid (ProtonFixes-herkenning)

# VC++ 2019 runtime via winetricks (de gedocumenteerde referentie-receptuur).
# NB: VC_RUNTIME_METHOD="redist" zou de gebundelde _CommonRedist gebruiken, maar
# de zoekzin in install_vcrun2019.sh matcht de bestandsnaam vc_redist_x64.exe
# niet (find -iname behandelt de punt letterlijk).
export VC_RUNTIME_METHOD="winetricks"

# --- Schalen/fullscreen (Wayland) ---
# De game tekende in een venster linksboven met zwarte randen onder en rechts:
# WineD3D-onder-Wayland schaalt het venster niet naar het scherm. gamescope
# forceert wél een echte fullscreen-output. GAME_GAMESCOPE_RES staat op de
# native monitormode (1920x1080) zodat gamescope niets onnodig schaalt.
# De wrap wordt door game-common.sh (_gscope_argv) opgebouwd.
export GAME_GAMESCOPE="1"
export GAME_GAMESCOPE_RES="1920x1080"

# --- Provision hooks (bij eerste run: prefix setup) ---
PROVISION_HOOKS=("install_vcrun2019" "install_dxvk")

# Geen PRE_LAUNCH_HOOKS: disable_winebus is een toetsenbordfix voor games met
# een winebus-probleem en is hier niet aantoonbaar nodig.
#
# Nog NIET toegevoegd, pas na een opstarttest die het afdwingt:
#   install_win7  — forceert win7 i.p.v. de Wine-default. De referentie-prefix
#                   staat op 6.1, maar de werkende Automation Empire-prefix
#                   staat op 6.3/win10; die twee botsen en vragen om een test.

# --- Core laden EN pas daarna game_main aanroepen ---
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

game_main "$@"