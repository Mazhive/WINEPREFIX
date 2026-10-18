#!/bin/bash
# mame.sh — MAME (volledige set) (wrapper naar emu-launch.sh)
export GAME_SYSTEM="mame"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
