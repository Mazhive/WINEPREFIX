#!/bin/bash
# neogeo.sh — Neo Geo (AES) (wrapper naar emu-launch.sh)
export GAME_SYSTEM="neogeo"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
