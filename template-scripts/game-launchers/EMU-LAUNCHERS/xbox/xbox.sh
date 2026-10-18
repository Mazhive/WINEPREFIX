#!/bin/bash
# og.sh — Xbox (OG) (wrapper naar emu-launch.sh)
export GAME_SYSTEM="xbox"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
