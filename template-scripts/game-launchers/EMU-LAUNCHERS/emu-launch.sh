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
    userconf="$(printf '%s\n' "$section" | sed -n 's/^userconf=//p' | head -1)"
    preconf="$(printf '%s\n' "$section" | sed -n 's/^preconf=//p' | head -1)"
    [ -n "$title" ] || title="$SYS"
}

# Standaard-config (preconf) naast de emulator automatisch in de user-config
# zetten. Nooit bestaande bestanden overschrijven (de gebruiker wint altijd).
_apply_preconf() {
    local emu_dir src dst
    [ -n "$emu" ] || return 0
    emu_dir="$(dirname "$emu")"
    src="${preconf:-$emu_dir/preconf}"
    dst="$userconf"
    [ -d "$src" ] || return 0
    if [ -z "$dst" ]; then
        echo "[emu] preconf gevonden in $src maar geen userconf= in de conf; overslaan." >&2
        return 0
    fi
    case "$dst" in "~"*) dst="$HOME${dst#\~}" ;; esac
    mkdir -p "$dst" 2>/dev/null || return 0
    if cp -rn "$src"/. "$dst"/ 2>/dev/null; then
        echo "[emu] standaard-config toegepast: $src → $dst" >&2
    fi
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

# Standaard-config toepassen zodat de gebruiker niets hoeft in te stellen.
_apply_preconf

# Map als rom? Zoek een rom-bestand in de map, of pack de map naar een iso.
if [ -d "$GAME_ROM" ] && [ "${accept_dir:-0}" != "1" ]; then
    _rom_in_dir() {
        # Voorkeur: iso, daarna andere bekende rom-/schijfimage-types.
        # Een echte folder-dump (PS2/PSX met SYSTEM.CNF) is géén container.
        local d="$1" ext f
        [ -e "$d/SYSTEM.CNF" ] && return 1
        for ext in iso chd cso gcm bin img mdf nrg cue elf pbp rvz wbfs; do
            f="$(find "$d" -maxdepth 2 -type f -iname "*.$ext" 2>/dev/null | sort | head -1)"
            if [ -n "$f" ]; then
                printf '%s' "$f"
                return 0
            fi
        done
        return 1
    }

    _pack_iso() {
        # Pack een folder-dump naar een gecachte iso met xdvdfs.
        local d="$1" cache base out
        command -v xdvdfs >/dev/null 2>&1 || return 1
        cache="${XDG_CACHE_HOME:-$HOME/.cache}/gamelauncher/iso"
        mkdir -p "$cache" || return 1
        base="$(basename "$d" | tr -c 'A-Za-z0-9._-' '_' | cut -c1-40)"
        out="$cache/${base}_$(printf '%s' "$d" | sha1sum | cut -c1-16).iso"
        if [ -s "$out" ] && [ "$out" -nt "$d" ]; then
            printf '%s' "$out"
            return 0
        fi
        echo "[emu] iso maken van map: $d" >&2
        if xdvdfs pack "$d" "$out" >&2 && [ -s "$out" ]; then
            printf '%s' "$out"
            return 0
        fi
        return 1
    }

    rom_file="$(_rom_in_dir "$GAME_ROM" || true)"
    if [ -n "$rom_file" ]; then
        echo "[emu] rom in map gevonden: $rom_file"
        GAME_ROM="$rom_file"
    else
        iso="$(_pack_iso "$GAME_ROM" || true)"
        if [ -n "$iso" ]; then
            GAME_ROM="$iso"
        else
            echo "[emu] $title: dit is een map zonder rom-bestand."
            echo "[emu] Zet een iso in de map of installeer 'xdvdfs' om te packen."
            exit 1
        fi
    fi
fi

echo "[game] Starten: ${GAME_DISPLAY_NAME:-$GAME_ROM}"
echo "[emu] $title — $emu"

# Argumenten: %ROM% wordt vervangen door het rom-pad. Woorden in args zijn
# spatie-gescheiden tokens; %ROM% wordt veilig (zonder eval) gesubstitueerd,
# zodat paden met spaties/haakjes intact blijven.
_argv=()
if [ -n "$args" ]; then
    for _tok in $args; do
        _argv+=("${_tok//%ROM%/$GAME_ROM}")
    done
else
    _argv+=("$GAME_ROM")
fi
exec "$emu" "${_argv[@]}"
