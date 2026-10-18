#!/bin/bash
# turbogrfx.sh — TurboGrafx-16 (wrapper naar emu-launch.sh)
export GAME_SYSTEM="turbogrfx"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
