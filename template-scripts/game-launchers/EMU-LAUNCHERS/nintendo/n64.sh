#!/bin/bash
# n64.sh — Nintendo 64 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="n64"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
