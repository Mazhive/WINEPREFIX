#!/bin/bash
# nes.sh — NES (wrapper naar emu-launch.sh)
export GAME_SYSTEM="nes"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
