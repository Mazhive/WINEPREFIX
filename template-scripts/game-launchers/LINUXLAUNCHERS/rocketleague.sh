#!/bin/bash
# Rocket League — dun per-game launcher.
# Zie game-core/game-common.sh voor de logica; hier staat alleen de config.
#
# ── Recept / werklog (2026-10) ──────────────────────────────────────────
# Game: Rocket League retail PC-build (Psyonix, geen Steam/Proton-laag; UE3 met
#       TAGame/CookedPCConsole — dus GEEN Epic-/Steam-install, gewoon retail).
# Map:  lowercase "rocketleague" in WINDOWSGAMES (let op: Launcher-GAME_NAME is
#       CamelCase "RocketLeague", de padnaam is dus NIET gelijk aan de naam).
# Exe:  Binaries/Win64/RocketLeague.exe (38 MB) → WIN64-64build, geen x86-variant.
# cwd = game-root: UE3 schrijft Saved/Logs + Saved/Config daar; werkt hetzelfde
#       als de core's "cd $GAME_DIR".
# Renderer: D3D11.
# Referentie-prefix (alleen analyse): WINEPREFIX/movedprefixes/Rocket_League =
#       PLAIN WINE, WINDOWS 7 (CurrentVersion 6.1, ProductName "Microsoft
#       Windows 7"), WNED3D en NIET DXVK/vkd3d — bewijs uit de dll-groottes:
#       d3d11.dll 3,7 MB (wined3d-builtin; echte DXVK ~20 MB), dxgi.dll 2,4 KB
#       en vulkan-1.dll 82 KB (wine-stubs, dus geen echte Vulkan-ICD/loader).
#       dinput8.dll 33 KB + xinput1_3.dll 201 KB = eveneens wine-builtins.
#       Dus: GEEN Proton, GEEN DXVK, GEEN vkd3d — wined3d D3D11.
# Keuze: kaal starten op plain wine + win7-hook, precies het bewezen recept van
#       de referentie-prefix. Alleen uitbreiden wat de test écht breekt.
# Icon: gameicons/RocketLeaugue.png (typefout in de 'n') matchte GAME_NAME niet;
#       hernoemd naar RocketLeague.png zodat de genormaliseerde match in de
#       core (game_make_desktop) hem nu wel pakt.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

export GAME_NAME="RocketLeague"
# GAME_DIR is de default; de GUI / installpaths.conf (GAME_DIR_RocketLeague)
# bepaalt per gebruiker de uiteindelijke map (game_resolve_install_dir in de
# core).
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/rocketleague"
export GAME_EXE="$GAME_DIR/Binaries/Win64/RocketLeague.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Rocket League"
export GAME_ICON="RocketLeague.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# Plain wine (géén PROTON_ENABLED): D3D11 via wined3d — bewezen referentie.
# Eén hook: Windows 7, exact de versie van de werkende referentie-prefix.
# Geen export: PROVISION_HOOKS mag een array zijn, en bash-arrays overleven
# export niet naar subprocessen (zelfde reden als citiesskylines.sh).
PROVISION_HOOKS=(install_win7)
# Minimaal gestart zonder overige hooks; uitbreiden op basis van de test:
#   - shadercompile duurt lang / stotert             → GAME_GAMESCOPE (zie citieskylines.sh)
#   - ontbrekende DirectX-runtime bij foutmelding   → install_dxvk of install_vkd3d
#     (let op: referentie draait wined3d, dus eerst aantonen dat het breekt)

game_main "$@"