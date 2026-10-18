#!/bin/bash
# msx.sh — MSX (wrapper naar emu-launch.sh)
export GAME_SYSTEM="msx"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
