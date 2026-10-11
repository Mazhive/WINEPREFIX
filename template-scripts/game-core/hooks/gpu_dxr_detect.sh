#!/bin/bash
# hook: gpu-dxr-detect — pre-launch (bij ELKE start).
#
# Waarom
#   vkd3d-proton zet DXR (ray tracing) automatisch aan zodra de Vulkan-driver
#   de RT-extensies meldt. Op NVIDIA Pascal (o.a. GTX 1080 Ti) doet driver 580
#   dat via een software-pad, maar SOTTR crasht daarmee tijdens het laden
#   (vóór het menu). Bewijs in bevindingen/BEVINDINGEN-SOTTR.md: baseline met
#   DXR aan crasht, alleen VKD3D_CONFIG=nodxr doorstaat het laden.
#
#   Detectie via Vulkan-extensies is onbetrouwbaar (false positive op Pascal),
#   daarom kijken we naar het GPU-model: alleen bekende RT-families houden DXR
#   aan, al het overige (incl. onbekend) krijgt nodxr.
#
# Override
#   GAME_DXR=auto  (default) — RT-familie → DXR aan, anders nodxr
#   GAME_DXR=on              — DXR geforceerd aan (bv. exotische RT-kaart)
#   GAME_DXR=off             — DXR geforceerd uit (nodxr)

# GPU-naam ophalen (eerste hit): nvidia-smi → lspci → sysfs PCI-id.
_gpu_dxr_name() {
  local n c
  if command -v nvidia-smi >/dev/null 2>&1; then
    n="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)"
    [ -n "$n" ] && { printf '%s\n' "$n"; return 0; }
  fi
  if command -v lspci >/dev/null 2>&1; then
    n="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -n1)"
    [ -n "$n" ] && { printf '%s\n' "$n"; return 0; }
  fi
  for c in /sys/class/drm/card[0-9]*/device; do
    [ -r "$c/vendor" ] || continue
    n="$(cat "$c/vendor" 2>/dev/null):$(cat "$c/device" 2>/dev/null)"
    [ -n "$n" ] && { printf '%s\n' "$n"; return 0; }
  done
  return 1
}

# 0 = hardwarematige RT-cores (bekende familie), 1 = geen/onbekend.
_gpu_has_rt_cores() {
  local name="$1"
  case "$name" in
    *RTX*) return 0 ;;
  esac
  # AMD RDNA2+ (RX 6000/7000/9000, Radeon PRO W6xxx/W7xxx)
  if printf '%s' "$name" | grep -qiE 'RX [679][0-9]{3}|PRO W[67][0-9]{3}'; then
    return 0
  fi
  # Intel Arc
  if printf '%s' "$name" | grep -qiE '(^|[^A-Za-z])Arc([^A-Za-z]|$)'; then
    return 0
  fi
  return 1
}

hook_run() {
  local want="${GAME_DXR:-auto}"
  case "$want" in
    auto|on|off) ;;
    *) _log "hook(gpu-dxr-detect): GAME_DXR='$want' onbekend → auto."; want="auto" ;;
  esac

  local name rt=no
  name="$(_gpu_dxr_name 2>/dev/null || true)"
  [ -n "${name:-}" ] || name="(onbekend)"
  _gpu_has_rt_cores "$name" && rt=yes

  local off=0
  case "$want" in
    off)  off=1 ;;
    on)   off=0 ;;
    auto) [ "$rt" = yes ] && off=0 || off=1 ;;
  esac

  # Idempotent: alleen nodxr toevoegen als het nog niet in VKD3D_CONFIG staat.
  if [ "$off" = 1 ]; then
    case ",${VKD3D_CONFIG:-}," in
      *,nodxr,*) ;;
      *)
        if [ -n "${VKD3D_CONFIG:-}" ]; then
          export VKD3D_CONFIG="${VKD3D_CONFIG},nodxr"
        else
          export VKD3D_CONFIG="nodxr"
        fi
        ;;
    esac
  fi

  if [ "$off" = 1 ]; then
    _log "hook(gpu-dxr-detect): GPU='${name}' RT-cores=${rt} GAME_DXR=${want} → DXR uit (VKD3D_CONFIG='${VKD3D_CONFIG:-}')."
  else
    _log "hook(gpu-dxr-detect): GPU='${name}' RT-cores=${rt} GAME_DXR=${want} → DXR aan (VKD3D_CONFIG='${VKD3D_CONFIG:-}')."
  fi
}
