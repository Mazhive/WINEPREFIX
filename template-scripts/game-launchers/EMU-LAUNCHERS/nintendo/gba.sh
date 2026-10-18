#!/bin/bash
# gba.sh — Game Boy Advance (wrapper naar emu-launch.sh)
export GAME_SYSTEM="gba"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
