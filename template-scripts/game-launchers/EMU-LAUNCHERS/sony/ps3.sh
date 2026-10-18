#!/bin/bash
# ps3.sh — PlayStation 3 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="ps3"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
