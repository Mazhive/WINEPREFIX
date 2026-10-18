#!/bin/bash
# c64.sh — Commodore 64 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="c64"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
