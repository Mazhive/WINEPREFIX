#!/bin/bash
# snes.sh — Super Nintendo (wrapper naar emu-launch.sh)
export GAME_SYSTEM="snes"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
