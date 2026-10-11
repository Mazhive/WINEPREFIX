#!/usr/bin/env bash
# Myst 2021 Remake — Launcher script
# Unreal Engine 4-titel (Myst-Win64-Shipping.exe). Recept uit de werkende
# one-liner (bevindingen/BEVINDINGEN-Myst2021Remake.md): plain wine + Windows 7
# + native DXVK + d3dcompiler_43 + VC++2019, met D3D11 geforceerd via
# GAME_WINE_EXTRA_ARGS="-d3d11".
#
# Waarom -d3d11: de game kiest standaard D3D12. wined3d ondersteunt D3D12 niet
# ("dx12 not supported"), en D3D12 via dxvk is instabiel op AMD RADV. Met
# -d3d11 start de game op zowel wined3d als dxvk.
set -euo pipefail

export GAME_NAME="Myst2021Remake"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Myst2021Remake"
export GAME_EXE="$GAME_DIR/Myst/Binaries/Win64/Myst-Win64-Shipping.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Myst 2021 Remake"
export GAME_ICON="myst2021remake.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# Plain wine (géén Proton-runner) — conform de werkende one-liner.
export PROTON_ENABLED="0"
# gamescope uit (default); de one-liner gebruikte geen gamescope.
export GAME_GAMESCOPE="0"

# Wine-configuratie: stille logs. Gecko/Mono-dialogen onderdrukt de core al
# tijdens provisioning (mscoree=;mshtml=), dus geen WINEDLLOVERRIDES hier.
export WINEDEBUG="-all"

# Forceer D3D11 (voorkomt de D3D12-crash/instabiliteit op wined3d én dxvk).
export GAME_WINE_EXTRA_ARGS="-d3d11"

# Provision hooks (éénmalig bij verse prefix, in deze volgorde):
#   install_d3dcompiler_43 → native D3DCompiler_43 (game importeert direct)
#   install_vcrun2019      → VC++2019-runtimes (MSVCP140, VCRUNTIME140)
#   install_win7           → Windows 7 (CurrentVersion 6.1/7601)
#   install_dxvk           → native DXVK (d3d9/d3d10core/d3d11/dxgi=native)
PROVISION_HOOKS=("install_d3dcompiler_43" "install_vcrun2019" "install_win7" "install_dxvk")

# Geen pre-launch hooks nodig — conform de werkende one-liner.

# Core laden EN pas daarna game_main aanroepen.
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"