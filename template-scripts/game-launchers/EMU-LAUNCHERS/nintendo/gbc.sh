#!/bin/bash
# gbc.sh — Game Boy Color (wrapper naar emu-launch.sh)
export GAME_SYSTEM="gbc"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
