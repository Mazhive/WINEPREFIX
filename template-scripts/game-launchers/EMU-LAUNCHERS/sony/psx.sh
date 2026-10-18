#!/bin/bash
# psx.sh — PlayStation (PS1) (wrapper naar emu-launch.sh)
export GAME_SYSTEM="psx"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
