#!/bin/bash
# 3ds.sh — Nintendo 3DS (wrapper naar emu-launch.sh)
export GAME_SYSTEM="3ds"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
