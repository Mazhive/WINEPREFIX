#!/bin/bash
# emu-launch.sh — generieke emulator-launcher voor de Game Launcher Fork.
#
# Wordt aangeroepen door game-gui-fork.py met de env:
#   GAME_SYSTEM  = systeem-sleutel (sectie in emulation.conf, bv. "psx")
#   GAME_ROM     = volledig pad naar de rom (iso/cue/map)
#   GAME_DISPLAY_NAME = weergave-naam van de game
#
# Leest emulation.conf, bouwt het commando en start de emulator.
set -u

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# Config staat per PC in de home-map; de GUI geeft GAME_EMU_CONF mee.
# Valt terug op de repo-versie naast dit script.
HOME_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/gamelauncher/emulation.conf"
if [ -n "${GAME_EMU_CONF:-}" ]; then
    CONF="$GAME_EMU_CONF"
elif [ -f "$HOME_CONF" ]; then
    CONF="$HOME_CONF"
else
    CONF="$HERE/emulation.conf"
fi

SYS="${GAME_SYSTEM:-}"
if [ -z "$SYS" ]; then
    echo "[emu] FOUT: GAME_SYSTEM niet gezet."
    exit 1
fi
if [ -z "${GAME_ROM:-}" ]; then
    echo "[emu] FOUT: GAME_ROM niet gezet (game: ${GAME_DISPLAY_NAME:-?})."
    exit 1
fi
if [ ! -f "$CONF" ]; then
    echo "[emu] FOUT: emulation.conf niet gevonden: $CONF"
    exit 1
fi

_parse_section() {
    section="$(awk -v s="[$SYS]" 'BEGIN{f=0} /^\[/{f=($0==s)} f' "$CONF")"
    emu="$(printf '%s\n' "$section" | sed -n 's/^emu=//p' | head -1)"
    args="$(printf '%s\n' "$section" | sed -n 's/^args=//p' | head -1)"
    title="$(printf '%s\n' "$section" | sed -n 's/^title=//p' | head -1)"
    status="$(printf '%s\n' "$section" | sed -n 's/^status=//p' | head -1)"
    accept_dir="$(printf '%s\n' "$section" | sed -n 's/^accept_dir=//p' | head -1)"
    [ -n "$title" ] || title="$SYS"
}

_parse_section

if [ -z "$section" ]; then
    echo "[emu] $title: geen sectie [$SYS] in $CONF."
    echo "[emu] Voeg de sectie toe (zie README-game-gui-fork.md)."
    exit 1
fi

# Ontbreekt de emulator? Probeer te installeren via emu-install.sh en herlees.
if [ "$status" = "missing" ] || [ -z "$emu" ] || [ ! -e "$emu" ]; then
    echo "[emu] $title: emulator ontbreekt — installatie wordt geprobeerd."
    if GAME_SYSTEM="$SYS" GAME_EMU_CONF="$CONF" bash "$HERE/emu-install.sh"; then
        _parse_section
    fi
fi

if [ "$status" = "missing" ] || [ -z "$emu" ]; then
    echo "[emu] $title: emulator nog niet geconfigureerd."
    echo "[emu] Zet emu= en args= in $CONF (sectie [$SYS]) om deze games te starten."
    exit 1
fi

if [ ! -e "$emu" ]; then
    echo "[emu] FOUT: emulator niet gevonden: $emu"
    echo "[emu] Pas emu= aan in $CONF (sectie [$SYS])."
    exit 1
fi

if [ -d "$GAME_ROM" ] && [ "${accept_dir:-0}" != "1" ]; then
    echo "[emu] $title: dit is een map, maar deze emulator heeft een iso-bestand nodig."
    echo "[emu] Maak er een iso van (bv. 'xdvdfs pack <map> <uit.iso>')."
    exit 1
fi

echo "[game] Starten: ${GAME_DISPLAY_NAME:-$GAME_ROM}"
echo "[emu] $title — $emu"

rom_q="$(printf '%q' "$GAME_ROM")"
if [ -n "$args" ]; then
    cmd="$(printf '%s' "$args" | sed "s|%ROM%|$rom_q|g")"
    eval "exec \"\$emu\" $cmd"
else
    exec "$emu" "$GAME_ROM"
fi
