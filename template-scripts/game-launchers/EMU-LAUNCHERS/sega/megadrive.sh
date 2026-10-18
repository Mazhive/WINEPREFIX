#!/bin/bash
# megadrive.sh — Sega Mega Drive (wrapper naar emu-launch.sh)
export GAME_SYSTEM="megadrive"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
