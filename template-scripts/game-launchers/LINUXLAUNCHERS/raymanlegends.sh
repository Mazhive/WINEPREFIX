#!/bin/bash
# Rayman Legends — Plain Wine launcher via game-common.sh core
# Ubisoft, 32-bit. Werkende referentie: movedprefixes/242550/pfx (Windows 10.0,
# VC++2019 volledig, DXVK actief zonder DllOverrides).
#
# Drie dingen zijn nodig voor een werkende verse prefix, alle drie uit de
# referentie afgelezen:
#   1. win64-prefix       — zie PREFIX_ARCH hieronder.
#   2. DXVK + VC++2019    — PROVISION_HOOKS.
#   3. HKLM Steam-route   — PRE_LAUNCH_HOOKS hieronder. Zonder de sleutel
#      Ubisoft\RaymanLegendsSteam toont de game een dode "download Uplay"-menu.
#      Dat is GEEN exe-probleem en ook geen gamedir-probleem: uplay_r1_loader.dll
#      is een statische import die gewoon nooit door de exe wordt aangeroepen.

export GAME_NAME="RaymanLegends"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/RaymanLegends"
export GAME_EXE="$GAME_DIR/Rayman_Legends.exe"
# Rayman_Legends.exe is PE32, maar de werkende referentie (242550/pfx) is een
# WoW64-prefix (#arch=win64) en DAAR start het spel. De win32-prefix startte
# het exe wel zonder fout, maar het venster kwam nooit op (exitcode 0).
# Win64 is bovendien de veilige default: een win64-prefix draait 32- én
# 64-bits exe's, en winetricks vult dan beide DLL-mappen.
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="6"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Rayman Legends"
export GAME_ICON="Rayman.legends.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

export VC_RUNTIME_METHOD="winetricks"

# Provision hooks (verse prefix)
# raymanlegends_dxvk_nocfg is bewust weg: die kopieerde x64-DLL's uit de
# referentie-prefix in deze 32-bits prefix. Zie het kopcommentaar in die hook.
# install_dxvk is de generieke vervanger en WEL nodig: de game importeert d3d9 en
# de werkende referent draait op DXVK (d3d9/d3d11/dxgi/d3d12/d3dcompiler_47 in
# zowel system32 als syswow64, byte-identiek aan wat 'winetricks -q dxvk'
# oplevert). Zonder deze hook kreeg een verse prefix géén DXVK — de DXVK in de
# oude prefix kwam daar handmatig vandaan, niet uit provisioning. Dat maakte de
# launcher niet reproduceerbaar.
PROVISION_HOOKS=("install_dxvk" "raymanlegends_vcrun2019")

# Zet de HKLM Steam-route-sleutels (RaymanLegendsSteam/Launcher/Uninstall\Uplay).
# Zonder deze drie toont de game een dode "download Uplay"-menu; de werkende
# prefix heeft ze wél (movedprefixes/242550). Oude aanpak met een no-op stub voor
# uplay_r1_loader.dll is bewust vervallen: die raakte de gedeelde gamedir op NFS,
# terwijl de oorzaak in de prefix zit. In PRE_LAUNCH_HOOKS omdat provisioning
# over sloopt voor een bestaande prefix.
PRE_LAUNCH_HOOKS=("raymanlegends_steam_registry")

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"