#!/bin/bash
# hook: colinmcrea4-virtual-desktop — Wine Virtual Desktop met integer scaling
#
# Forceert de game in een virtueel Wine-bureaublad met integer scaling.
# Colin McRae 4 is 4:3 (640x480 native). We gebruiken een integer multiple
# virtual desktop (1280x960 = 2x, 1920x1440 = 3x) zodat Wine de game centreert.
#
# Strategie:
# 1. Detecteer monitor resolutie
# 2. Kies integer multiple van 640x480 die past (1280x960 of 1920x1440)
# 3. Forceer game resolutie via Wine registry + CenterFullscreen tweak

hook_run() {
  # Detecteer primaire monitor resolutie
  local mon_W=1920 mon_H=1080  # fallback

  if command -v xrandr >/dev/null 2>&1; then
    local res
    res=$(xrandr --query 2>/dev/null | grep ' connected primary' -A1 | tail -1 | awk '{print $1}')
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      mon_W=${res%x*}; mon_H=${res#*x}
    fi
  elif command -v wlr-randr >/dev/null 2>&1; then
    local res
    res=$(wlr-randr 2>/dev/null | grep -A3 'Enabled: yes' | grep -Eo '[0-9]+x[0-9]+' | head -1)
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      mon_W=${res%x*}; mon_H=${res#*x}
    fi
  elif command -v kscreen-doctor >/dev/null 2>&1; then
    local res
    res=$(kscreen-doctor -j 2>/dev/null | grep -o '"pixelSize":\[[0-9]*,[0-9]*\]' | head -1 | grep -o '[0-9]*' | tr '\n' 'x' | sed 's/x$//')
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      mon_W=${res%x*}; mon_H=${res#*x}
    fi
  fi

  # Integer multiples van 640x480 (game native resolutie)
  # 1x = 640x480, 2x = 1280x960, 3x = 1920x1440, 4x = 2560x1920
  local vdesk_W vdesk_H

  # Kies grootste integer multiple die past op monitor
  if [ "$mon_W" -ge 1920 ] && [ "$mon_H" -ge 1440 ]; then
    vdesk_W=1920; vdesk_H=1440  # 3x (beste kwaliteit)
  elif [ "$mon_W" -ge 1280 ] && [ "$mon_H" -ge 960 ]; then
    vdesk_W=1280; vdesk_H=960   # 2x (goede fallback)
  else
    vdesk_W=640; vdesk_H=480    # 1x (fallback)
  fi

  _log "hook(colinmcrea4-virtual-desktop): Monitor ${mon_W}x${mon_H} → Virtual Desktop ${vdesk_W}x${vdesk_H} (integer scaling)"

  # Exporteer voor game_launch in game-common.sh
  export WINE_VIRTUAL_DESKTOP="1"
  export WINE_DESKTOP_W="${vdesk_W}"
  export WINE_DESKTOP_H="${vdesk_H}"

  # Wine registry tweaks voor centered fullscreen
  # Deze worden uitgevoerd in game_launch na prefix setup
  export COLINMCREA4_CENTER_FULLSCREEN="1"
}