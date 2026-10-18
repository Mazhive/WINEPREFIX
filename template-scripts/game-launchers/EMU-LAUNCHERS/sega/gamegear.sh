#!/bin/bash
# gamegear.sh — Sega Game Gear (wrapper naar emu-launch.sh)
export GAME_SYSTEM="gamegear"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
