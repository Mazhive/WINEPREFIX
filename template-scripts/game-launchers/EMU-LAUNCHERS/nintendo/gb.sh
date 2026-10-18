#!/bin/bash
# gb.sh — Game Boy (wrapper naar emu-launch.sh)
export GAME_SYSTEM="gb"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
