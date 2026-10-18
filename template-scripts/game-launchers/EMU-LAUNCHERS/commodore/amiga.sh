#!/bin/bash
# amiga.sh — Amiga (wrapper naar emu-launch.sh)
export GAME_SYSTEM="amiga"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
