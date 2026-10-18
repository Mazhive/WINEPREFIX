#!/bin/bash
# famicom.sh — Famicom / FDS (wrapper naar emu-launch.sh)
export GAME_SYSTEM="famicom"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
