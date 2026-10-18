#!/bin/bash
# psp.sh — PlayStation Portable (wrapper naar emu-launch.sh)
export GAME_SYSTEM="psp"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
