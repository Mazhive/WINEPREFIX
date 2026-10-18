#!/bin/bash
# c128.sh — Commodore 128 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="c128"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
