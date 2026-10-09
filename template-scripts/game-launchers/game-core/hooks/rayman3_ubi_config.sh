#!/bin/bash
# hook: rayman3-ubi-config — schrijft ubi.ini met dynamische video-instellingen.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PRE_LAUNCH_HOOKS=( "rayman3_ubi_config" )
#
# Detecteert de primaire monitor resolutie (X11 via xrandr, Wayland via wlr-randr)
# en schrijft een ubi.ini met:
#   - Gli_Mode = gedetecteerde resolutie @ 32-bit
#   - FullScreen=0 (borderless windowed) voor cross-monitor compatibiliteit
#   - TnL=1, TriLinear=1 voor optimale rendering
#   - Video_AutoAdjustQuality=0 (handmatige resolutie)
#
# Deze hook is idempotent: de waarden worden bij elke start overschreven.

hook_run() {
  local ubi_dir="$PREFIX_PATH/drive_c/windows/Ubisoft"
  local ubi_ini="$ubi_dir/ubi.ini"

  mkdir -p "$ubi_dir"

  # Detecteer primaire monitor resolutie
  local W=1920 H=1080  # fallback

  if command -v xrandr >/dev/null 2>&1; then
    # X11: haal actieve primaire monitor resolutie op
    local res
    res=$(xrandr --query 2>/dev/null | grep ' connected primary' -A1 | tail -1 | awk '{print $1}')
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      W=${res%x*}; H=${res#*x}
    fi
  elif command -v wlr-randr >/dev/null 2>&1; then
    # Wayland (wlr-randr): haal eerste enabled output resolutie op
    local res
    res=$(wlr-randr 2>/dev/null | grep -A3 'Enabled: yes' | grep -Eo '[0-9]+x[0-9]+' | head -1)
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      W=${res%x*}; H=${res#*x}
    fi
  elif command -v kscreen-doctor >/dev/null 2>&1; then
    # KDE Wayland: kscreen-doctor
    local res
    res=$(kscreen-doctor -j 2>/dev/null | grep -o '"pixelSize":\[[0-9]*,[0-9]*\]' | head -1 | grep -o '[0-9]*' | tr '\n' 'x' | sed 's/x$//')
    if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
      W=${res%x*}; H=${res#*x}
    fi
  fi

  _log "hook(rayman3-ubi-config): gedetecteerde resolutie ${W}x${H}"

  cat > "$ubi_ini" <<EOF
[Rayman3]
Gli_Mode=1 - ${W} x ${H} x 32
Adapter=0
TnL=1
TriLinear=1
Identifier=AEB2CDD4-6E41-43EA-941C-8361CC760781
DynamicShadows=0
StaticShadows=0
Video_BPP=32
Video_WantedQuality=2
Video_AutoAdjustQuality=0
FullScreen=0
Camera_VerticalAxis=-1
Camera_HorizontalAxis=2
VignettesFile=Vignette.cnt
TexturesQuality=32
TexturesCompressed=1
Language=English
EOF

  _log "hook(rayman3-ubi-config): ubi.ini geschreven naar $ubi_ini (${W}x${H}, borderless windowed)"
}