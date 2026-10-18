#!/bin/bash
# vic20.sh — Commodore VIC-20 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="vic20"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
