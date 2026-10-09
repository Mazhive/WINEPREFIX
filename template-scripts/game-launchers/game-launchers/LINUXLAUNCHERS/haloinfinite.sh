#!/bin/bash
# haloinfinite.sh — Halo Infinite via Proton-runner (non-Steam, CODEX Steam-emu).
#
# 64-bit, D3D12 → VKD3D-Proton komt uit de GE-Proton-runner zelf (geen losse
# install_vkd3d nodig). De prefix wordt ALTIJD vers opgebouwd (wineboot -i, zie
# game-common.sh): er wordt nooit een bestaande prefix gekopieerd of vanaf de
# NFS-share gebruikt.
#
# VC++-runtime: de game roept concrt140.dll (+ msvcp140/vcomp140/...) aan bij
# init. Wine's builtin concrt140 mist die entry → "unimplemented function
# concrt140.dll..." → abort. Hook install_haloinfinite_vcrun levert de native
# MS-DLL's (winetricks vcrun2022 / gebundelde VC_redist.x64.exe), zet de juiste
# DllOverrides en zet losse DLL's naast de exe weg. De pre-launch guard
# haloinfinite_stray_dlls herhaalt dat wegzetten bij elke start.

export GAME_NAME="haloinfinite"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Halo_Infinite"
export GAME_EXE="$GAME_DIR/HaloInfinite.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Halo Infinite"
export GAME_ICON="HaloInfinite.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# ── Proton / runner ──────────────────────────────────────────
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton9-27"
export STEAM_APPID="1240440"   # Halo Infinite Steam appid (ProtonFixes + compatdata)
export DISABLE_ESYNC=0
export PROTONFIXES_DISABLE=1
# NVIDIA: DXVK-NVAPI 0.9.0 mist NvAPI_D3D12_CreateHeap. Op een NVIDIA-GPU kiest
# Halo Infinite dat NVAPI-pad en crasht direct na de D3D12-device-init (eigen
# crash.txt, exit 10, géén page fault). NVAPI uitschakelen → Halo neemt het
# generieke pad en start. Op AMD is NVAPI toch afwezig, dus geen effect.
export PROTON_DISABLE_NVAPI="1"

# ── Wine/DXVK-configuratie ───────────────────────────────────
export WINEDEBUG="-all"
export VKD3D_SHADER_CACHE_SIZE="4"
export VKD3D_CONFIG="force_static_cbv"
export DXVK_HUD="fps,msgs"
# Gamescope optioneel (default uit; GUI-checkbox kan aanzetten)
export GAME_GAMESCOPE="0"

# ── Hooks ────────────────────────────────────────────────────
PRE_PROVISION_HOOKS=("ensure_geproton9_27")
PROVISION_HOOKS=("install_haloinfinite_vcrun")
PRE_LAUNCH_HOOKS=("haloinfinite_stray_dlls")

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
