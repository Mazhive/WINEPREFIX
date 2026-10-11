#!/bin/bash
# Crysis — dun per-game launcher.
# Zie game-core/game-common.sh voor de logica; hier staat alleen de config.
#
# ── Recept / werklog (2026-09) ──────────────────────────────────────────
# Game: Crysis 1 build 5767 (retail/EA, geen Steam/emu, geen _CommonRedist).
# Exe:  Bin64/Crysis.exe = "C1-Launcher Game v8 64-bit" (custom launcher) die
#       via Bin64/Crysis.ini (exe=crysis64.exe) de echte Crysis64.exe start.
#       Z64-bit; laad de engine-dll's uit Bin64 (wine doet dat automatisch
#       vanuit de exe-map). cwd = game-root: werkt (Game.log schrijft netjes
#       aan de game-root, zelfde als core's "cd $GAME_DIR").
# Renderer: D3D9/D3D10. Bewijsrun bereikte main menu via D3D10-renderer.
# Referentie-prefix (alleen analyse): WINEPREFIXES.old/Crysis.1 = PLAIN WINE,
#       Windows 10 (build 19043), VC++2005-redist x86+x64 — GEEN Proton, geen
#       DXVK. Engine-dlls importeren MSVCR80 (VS2005) + CryInput gebruikt
#       DINPUT8/XINPUT1_3 (wine-builtins).
# Keuze: kaal starten (plain wine, win64, geen hooks) en alleen uitbreiden
#       wat de test écht breekt, gebaseerd op de werkende referentie.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

export GAME_NAME="Crysis"
# GAME_DIR is de default; de GUI / installpaths.conf (GAME_DIR_Crysis) bepaalt
# per gebruiker de uiteindelijke map (game_resolve_install_dir in de core).
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Crysis"
export GAME_EXE="$GAME_DIR/Bin64/Crysis.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Crysis"
export GAME_ICON="Crysis.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# Plain wine (géén PROTON_ENABLED): D3D9/D3D10 via wined3d — bewezen referentie.
# Minimaal gestart zonder PROVISION_HOOKS; uitbreiden op basis van de test:
#   - Windows-versie win10 (mirror referentie)        → install_win10 (hook)
#   - MSVCR80-issue (wine-builtin faalt)              → install_vcrun2005 (hook)
#   - shader/font-problemen (d3dx9 ontbreekt)         → install_d3dx9

game_main "$@"