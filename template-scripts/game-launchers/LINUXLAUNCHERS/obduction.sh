#!/usr/bin/env bash
set -euo pipefail
# obduction.sh — Obduction via Proton-runner (non-Steam game),
# gebaseerd op Stray-recept (UE4 + Windows 7 + VC++2019).
#
# Lokale, VERSE prefix (wineboot -i) — geen kopie van een bestaande prefix.
# De prefix 306760 is oorspronkelijk voor Wolfenstein II (Vulkan) en is
# fundamenteel verkeerd voor deze UE4/DX11-game. Zie BEVINDINGEN-Obduction.md.

export GAME_NAME="Obduction"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Obduction"
export GAME_EXE="$GAME_DIR/Obduction/Binaries/Win64/Obduction-Win64-Shipping.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"
export GAME_DISPLAY_NAME="Obduction"
export GAME_ICON="Obduction.png"

export STEAM_APPID="306760"
# Zie BEVINDINGEN-Obduction.md: basis-recept is Windows 7 + VC++2019,
# niet de oorspronkelijke prefix 306760. Geen Proton voor baseline-test.

# MangoHud: als GUI-checkbox aangevinkt, gebruik mangohud commando wrapper
if [ "${GUI_MANGOHUD:-0}" = "1" ]; then
    export WINE_CMD="mangohud wine"
    export MANGOHUD_CONFIGFILE="${MANGOHUD_CONFIGFILE:-$HOME/.config/mangohud/mangohud.conf}"
else
    export WINE_CMD="wine"
fi

# Basisinstellingen conform Stray-recept (bewerkt UE4-recept).
VC_RUNTIME_METHOD="winetricks"
PROVISION_HOOKS=("install_vcrun2019" "install_win7")
# Geen PRE_LAUNCH_HOOKS, geen GAME_GAMESCOPE, geen DXVK overrides
# tenzij baseline (stap 4 van BEVINDINGEN) faalt.

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"