#!/bin/bash
# nds.sh — Nintendo DS (wrapper naar emu-launch.sh)
export GAME_SYSTEM="nds"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
