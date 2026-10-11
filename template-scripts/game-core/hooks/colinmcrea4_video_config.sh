#!/bin/bash
# hook: colinmcrea4-video-config — Gamescope (Wayland) of Wine Virtual Desktop (fallback)
# voor correcte fullscreen/windowed resolutie handling.
#
# Colin McRae Rally 04 (DirectX 9, 2004) heeft geen in-game video config.
# De game probeert DirectX display mode te switchen, wat faalt op moderne
# compositors → klein scherm linksboven, rest zwart.
#
# Strategie:
# 1. Wayland + gamescope beschikbaar → Gamescope (beste upscaling, input handling)
#    - Inner resolution = 640x480 (game's native fullscreen res)
#    - Outer resolution = monitor resolutie (upscaling via gamescope)
# 2. Anders → Wine Virtual Desktop (werkt overal, X11 + Wayland)
#
# Detecteert monitor resolutie dynamisch via xrandr/wlr-randr/kscreen-doctor.

hook_run() {
  # Detecteer primaire monitor resolutie
  local W=1920 H=1080  # fallback

  if command -v xrandr >/dev/null 2>&1; then
    local res
    res=$(xrandr --query 2>/dev/null | grep ' connected primary' -A1 | tail -1 | awk '{print $1}')
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      W=${res%x*}; H=${res#*x}
    fi
  elif command -v wlr-randr >/dev/null 2>&1; then
    local res
    res=$(wlr-randr 2>/dev/null | grep -A3 'Enabled: yes' | grep -Eo '[0-9]+x[0-9]+' | head -1)
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      W=${res%x*}; H=${res#*x}
    fi
  elif command -v kscreen-doctor >/dev/null 2>&1; then
    local res
    res=$(kscreen-doctor -j 2>/dev/null | grep -o '"pixelSize":\[[0-9]*,[0-9]*\]' | head -1 | grep -o '[0-9]*' | tr '\n' 'x' | sed 's/x$//')
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      W=${res%x*}; H=${res#*x}
    fi
  fi

  _log "hook(colinmcrea4-video-config): gedetecteerde resolutie ${W}x${H}"

  # Bepaal launch wrapper
  # GAME_GAMESCOPE=1 (via GUI checkbox of env) forceert gamescope op Wayland
  # GAME_GAMESCOPE_RES="WxH" kan interne resolutie forceren
  local use_gamescope=0
  if [ "${GAME_GAMESCOPE:-0}" = "1" ] && [ "$XDG_SESSION_TYPE" = "wayland" ] && command -v gamescope >/dev/null 2>&1; then
    use_gamescope=1
  elif [ "$XDG_SESSION_TYPE" = "wayland" ] && command -v gamescope >/dev/null 2>&1; then
    # Default op Wayland: gamescope gebruiken voor betere fullscreen handling
    use_gamescope=1
    export GAME_GAMESCOPE=1
  fi

  # 1280x960 = 2x integer multiple van de 640x480-native resolutie van CMR4.
  # Dit is de waarde die empirisch werkt: de standalone-launcher draaide de game
  # succesvol als `gamescope -w 1280 -h 960 -f`. Zonder expliciete -W/-H kiest
  # gamescope zelf de native monitormode en landt CMR4 op 640x480 in een
  # hoekje (of crasht hij op de display-mode-change).
  local want_res="1280x960"

  if [ "$use_gamescope" = "1" ]; then
    _log "hook(colinmcrea4-video-config): gamescope, buffer $want_res, fullscreen op ${W}x${H}"

    # Exporteer voor _gamescope_wrap in game-common.sh, dat hieruit
    # `gamescope -f -W 1280 -H 960 --` bouwt.
    export GAME_GAMESCOPE=1
    export GAME_GAMESCOPE_RES="$want_res"

    # Disable SDL3 dynamic API (game uses SDL 1.2/2.0, not 3)
    export SDL3_DYNAMIC_API=0
  else
    # Wine Virtual Desktop. Let op: onder XWayland krijgt de virtual desktop
    # de schermgrootte en loopt de fullscreen-vraag van CMR4 vast; dit is dus
    # alleen een fallback voor een echte X11-sessie.
    _log "hook(colinmcrea4-video-config): Wine Virtual Desktop $want_res (X11-fallback)"

    export WINE_VIRTUAL_DESKTOP="1"
    export WINE_DESKTOP_W="${want_res%x*}"
    export WINE_DESKTOP_H="${want_res#*x}"

    # Disable SDL3 dynamic API
    export SDL3_DYNAMIC_API=0
  fi
}