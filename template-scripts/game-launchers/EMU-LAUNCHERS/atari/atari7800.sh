#!/bin/bash
# atari7800.sh — Atari 7800 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="atari7800"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
