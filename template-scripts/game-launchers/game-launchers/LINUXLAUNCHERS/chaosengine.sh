#!/bin/bash
# The Chaos Engine (Remastered) — dun per-game launcher.
# Zie game-core/game-common.sh voor de logica; hier staat alleen de config.
#
# ── Recept / werklog (2026-10) ──────────────────────────────────────────
# Game: GOG-retail PC-build (1998 Bitmap Brothers, "Remastered" uit 2013).
#       GOG-markers in de map: goggame.dll, gfw_high.ico, GameuxInstallHelper.dll.
# Exe:  "The Chaos Engine - Remastered.exe" (5,2 MB) — RECHTSTEEKS gestart, niet
#       via de GOG-shortcut. De oude linux.sh deed wél wine …/Public/Desktop/
#       "The Chaos Engine - Remastered.lnk"; dat is een Windows-.lnk als
#       launchargument en kooprt niets. De .lnk verwijst toch al naar de Z:\…exe
#       met cwd = game-root, dus weet dezelfde exe gestart worden zonder hem.
#       PREFIX_ARCH=win32 (32-bit exe) → eerste win32-launcher in de set;
#       i386-ondersteuning is aanwezig in /opt/wine-stable.
# cwd = game-root (Data/-structuur; schrijft daar Saved/).
# Renderer: OpenGL. De exe importeert OPENGL32.dll + glew32.dll → wined3d over
#       Mesa radeonsi (RX 7600). DXVK is hier NIET van toepassing (geen D3D).
# Icoon: gameicons/ChaosEngine.png = 256x256-frame uit de eigen gfw_high.ico
#       (GOG's icoon van deze game), met PIL gehaald. Genormaliseerde match op
#       GAME_NAME "ChaosEngine" is exact.
#
# ── Uitkomst meting (2026-10) ────────────────────────────────────────────
# Klachten bij de oude opzet: GELUID LAGGY en STOTTEREN. Beide zijn opgelost,
# en beide bleken gevolgen van één ding: het HERGEBRUIKEN van een bestaande
# prefix vanaf de NFS-share (linux.sh startte
# movedprefixes/32bit.Chaos.engine/pfx). Met een verse lokale prefix in
# $HOME/GAMEPREFIXES zijn geluid én gameplay goed. Conform de huisregel in
# game-common.sh wordt de prefix altijd lokaal en vers aangemaakt.
#
# Er staan daarom GEEN hooks en GEEN WINEDLLOVERRIDES — de meting zegt dat die
# niet nodig zijn. Twee vermoedens zijn bewust getest en uitgewerkt:
#
# 1. GELUID — de exe importeert OpenAL32.dll rechtstreeks (objdump -p). De
#    OpenAL32.dll van de game (109 KB) is de CREATIVE ADI-wrapper: zijn strings
#    noemen ADI_OAL.DLL en CT_OAL.DLL, die nergens bestaan. Gemeten met
#    WINEDEBUG=+loaddll dat de keten inderdaad zo loopt:
#      OpenAL32.dll : native (uit de gamedir)
#        → wrap_oal.dll : native (uit de gamedir)
#          → dsound.dll : builtin ×2      (DirectSound-fallback)
#            → winepulse.drv : builtin
#              → PipeWire (sink-input "The Chaos Engine - Remastered.exe")
#    MAAR dit klinkt prima. Er is dus GEEN OpenAL-fix nodig. Wel vastgelegd:
#    wine-11.0 heeft geen openal32 (noch PE noch unix) en de openal32.dll in de
#    oude prefix is 1032 bytes met de string "Wine placeholder DLL" =
#    functioneel leeg. Toch geen probleem, want de game levert zijn eigen
#    native OpenAL mee en de DirectSound-fallback doet het werk.
#
# 2. STOTTEREN — winebus. In het log van de verse prefix:
#    "failed to start: 1115" voor winebus (en PlugPlay, MountMgr, Eventlog,
#    NDIS, nsiproxy, wineusb, winebth). De service draait dus helemaal niet in
#    een verse prefix; services.exe zat op 0,0% CPU, wineserver 4%, winedevice
#    2%. PRE_LAUNCH_HOOKS=(disable_winebus) zou een no-op zijn geweest.
#    NFS is eveneens uitgesloten als oorzaak: de share leest op 1,5 GB/s en 200
#    metadata-opvragingen kosten 0,00 s.
#
# Overig uit het log, onschuldig en niet bewezen relevant:
#   "SDL Dynamic API Failure! … SDL3_DYNAMIC_API" — de game valt terug op de
#     eigen 2013-SDL.dll uit de gamedir; gameplay is goed.
#   ole:CoMarshalInterface / start_rpcss, heap:RtlSetHeapInformation,
#     setupapi:do_file_copyW — bekende wine-ruis.
#
# De linux*.sh in de gamedir zijn bewust laten liggen (die map is data, geen
# template-scripts). linux.noa.sh is overigens dubbel stuk: het zet WINEPREFIX
# naar $WINEPREFIX/32bit.Chaos.engine.noa/pfx (bestaat niet) en start de .lnk
# uit een andere prefix.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

export GAME_NAME="ChaosEngine"
# GAME_DIR is de default; de GUI / installpaths.conf (GAME_DIR_ChaosEngine)
# bepaalt per gebruiker de uiteindelijke map (game_resolve_install_dir).
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Chaos_Engine_-_Remastered"
export GAME_EXE="$GAME_DIR/The Chaos Engine - Remastered.exe"
export PREFIX_ARCH="win32"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Chaos Engine"
export GAME_ICON="ChaosEngine.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# NULMETING-BEWIJS: er staan bewust geen PROVISION_HOOKS, geen PRE_LAUNCH_HOOKS
# en geen WINEDLLOVERRIDES. Zie de "Uitkomst meting" hierboven; uitbreiden op
# basis van wat een test écht breekt, niet op basis van vermoedens.

game_main "$@"