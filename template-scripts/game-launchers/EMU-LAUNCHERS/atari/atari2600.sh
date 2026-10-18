#!/bin/bash
# atari2600.sh — Atari 2600 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="atari2600"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
