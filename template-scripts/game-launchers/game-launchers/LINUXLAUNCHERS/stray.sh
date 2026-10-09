#!/bin/bash
# Stray — Plain Wine launcher via game-common.sh core
# Unreal Engine 4-titel (bootstrapper Stray.exe → Shipping). Werkende referentie:
# movedprefixes/Stray.2022 draait op Windows 7 (6.1), met volledige VC++2019-runtime,
# zonder DXVK, zonder DllOverrides, zonder gamescope.

# --- Basisinstellingen (ALLE exports VOOR sourcing game-common.sh) ---
export GAME_NAME="Stray"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Stray"
export GAME_EXE="$GAME_DIR/Stray.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Stray"
export GAME_ICON="Stray.jpg"

export GAME_LAUNCHER="$(readlink -f "$0")"

export STEAM_APPID="1332010"  # Stray Steam appid (indien relevant)

# VC++ 2019 runtime via winetricks (referentie-receptuur).
export VC_RUNTIME_METHOD="winetricks"

# --- Provision hooks (bij eerste run: prefix setup) ---
# install_vcrun2019: levert de volledige VC++2019-runtime (8 DLL's)
# install_win7: zet Windows-versie op 6.1 (Windows 7) zoals de werkende referentie
PROVISION_HOOKS=("install_vcrun2019" "install_win7")

# Geen PRE_LAUNCH_HOOKS, geen GAME_GAMESCOPE, geen DXVK — conform werkende referentie.

# --- Core laden EN pas daarna game_main aanroepen ---
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

game_main "$@"