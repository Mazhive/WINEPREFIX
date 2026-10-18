#!/bin/bash
# ps2.sh — PlayStation 2 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="ps2"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
