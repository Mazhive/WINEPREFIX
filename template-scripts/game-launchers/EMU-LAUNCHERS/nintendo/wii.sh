#!/bin/bash
# wii.sh — Wii (wrapper naar emu-launch.sh)
export GAME_SYSTEM="wii"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
