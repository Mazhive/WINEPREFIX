#!/bin/bash
# mastersystem.sh — Sega Master System (wrapper naar emu-launch.sh)
export GAME_SYSTEM="mastersystem"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
