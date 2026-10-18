#!/bin/bash
# atarilynx.sh — Atari Lynx (wrapper naar emu-launch.sh)
export GAME_SYSTEM="atarilynx"
exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
