#!/bin/bash
# mamemame4all.sh — MAME4ALL (wrapper naar emu-launch.sh)
export GAME_SYSTEM="mamemame4all"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
