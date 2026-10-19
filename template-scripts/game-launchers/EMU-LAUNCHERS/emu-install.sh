#!/bin/bash
# emu-install.sh — installeer/koppel de emulator voor GAME_SYSTEM.
#
# Dunne runner: sourcet game-common.sh (voor _log/_busy_* en _run_hook) en
# voert de module game-core/hooks/install_emu.sh uit. De GUI en emu-launch.sh
# roepen dit script aan met GAME_SYSTEM (en optioneel GAME_EMU_CONF).
set -u

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CORE="$(readlink -f "$HERE/../../game-core/game-common.sh")"
if [ ! -f "$CORE" ]; then
    echo "[emu] game-common.sh niet gevonden: $CORE"
    exit 1
fi
# shellcheck disable=SC1090
. "$CORE"

if [ -z "${GAME_SYSTEM:-}" ]; then
    echo "[emu] FOUT: GAME_SYSTEM niet gezet."
    exit 1
fi

CONF_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/gamelauncher/emulation.conf"
if [ -n "${GAME_EMU_CONF:-}" ]; then
    export EMU_CONF="$GAME_EMU_CONF"
elif [ -f "$CONF_HOME" ]; then
    export EMU_CONF="$CONF_HOME"
else
    export EMU_CONF="$HERE/emulation.conf"
fi
export EMU_REPO_CONF="$HERE/emulation.conf"

_run_hook install_emu
exit $?
