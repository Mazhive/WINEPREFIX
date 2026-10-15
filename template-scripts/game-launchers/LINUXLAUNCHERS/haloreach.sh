#!/usr/bin/env bash
# Halo: Reach (MCC, CODEX) — dunne per-game launcher.
# Zie game-core/game-common.sh voor de logica; hier staat alleen de config.
#
# ── Recept (BEVINDINGEN-HaloMCC.md, 2026-10-14) ─────────────────────────
# De game is Halo: Reach; mcclauncher.exe is alleen de CODEX-stub (PE32) die
# MCC/Binaries/Win64/MCC-Win64-Shipping.exe start — vandaar de MCC-map/prefix.
# Oorzaak van "CreateProcess() failed": de werkmap stond niet op de game-root.
# De stub start de Shipping-exe met een RELATIEF pad; Wine neemt de shell-cwd
# over als Windows-werkmap. De core zet de cwd al goed: game_launch() doet
# `cd "$GAME_DIR"` (game-common.sh:818) vóór de wine-aanroep — dus geen eigen
# cd in deze dunne launcher nodig.
#
# Meetlat movedprefixes/halo.mcc: plain wine, GEEN DXVK, GEEN native vcrun
# (d3d11/msvcp140/... byte-identiek aan Wine 11.0 builtins). Het spel liep op
# wined3d. Stap 4 van de bevinding: native vcrun provisionen als vangnet.
set -euo pipefail

export GAME_NAME="HaloReach"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Halo-Reach"
export GAME_EXE="$GAME_DIR/mcclauncher.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Halo: Reach"
export GAME_ICON="HaloReach.png"
export GAME_LAUNCHER="$(readlink -f "$0")"

# VC++2017/2019 (v14.x) — zie BEVINDINGEN-HaloMCC.md stap 4.
PROVISION_HOOKS=("install_vcrun2019")

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
