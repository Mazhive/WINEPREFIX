#!/bin/bash
# amstradcpc.sh — Amstrad CPC (wrapper naar emu-launch.sh)
export GAME_SYSTEM="amstradcpc"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
