#!/bin/bash
# Rayman 3: Hoodlum Havoc — Plain Wine launcher via game-common.sh core
# Ubisoft, 32-bit. Referentie: movedprefixes/821091567/pfx (Windows 10.0,
# DXVK actief, d3d8 via DXVK native, VC++2019 volledig).
#
# Belangrijk: de game gebruikt een d3d8.dll wrapper (BetterRayman3.dll) in de
# gamedir. Met DXVK 1.7+ (install_dxvk hook) wordt d3d8 native geleverd door
# DXVK — de game's wrapper wordt dan overgeslagen, wat de lag oplost.
# De originele d3d8.dll en BetterRayman3.dll in de gamedir blijven onaangetast.

export GAME_NAME="Rayman3HoodlumHavoc"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Rayman3_hoodlum_havoc"
export GAME_EXE="$GAME_DIR/Rayman3.exe"
# 32-bit game, maar win64-prefix is veilig: draait 32- en 64-bit, winetricks
# vult beide DLL-mappen (system32 + syswow64).
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Rayman 3: Hoodlum Havoc"
export GAME_ICON="Rayman3Hoodlum_Havoc.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

export VC_RUNTIME_METHOD="winetricks"
export STEAM_APPID="8210"

# 3rd-party configuratie-tool (optioneel, via GUI "Configure" knop)
# Wordt gevonden via $TOOLS_DIR/3rdparty/$GAME_SETUP_TOOL
export GAME_SETUP_TOOL="R3_Setup_DX8.exe"
export GAME_SETUP_TOOL_NAME="Rayman 3 Setup"

# Provision hooks (verse prefix)
# install_dxvk: DXVK native (d3d8/d3d9/d3d11/dxgi) — lost de lag door de
# game's d3d8-wrapper over te slaan.
# install_d3dx9: d3dcompiler_43 + d3dx9_24..43 voor shader-compatibiliteit.
# rayman3_vcrun2019: VC++2015-2019 runtime (32-bit in syswow64).
PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "rayman3_vcrun2019")

# Pre-launch hooks (bij elke start)
# rayman3_steam_registry: forceert Ubisoft Steam-route via HKLM-sleutels.
# rayman3_ubi_config: schrijft ubi.ini met bekende video-instellingen.
PRE_LAUNCH_HOOKS=("rayman3_steam_registry" "rayman3_ubi_config")

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"