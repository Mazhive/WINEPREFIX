#!/bin/bash
# hook: vkd3d-cache-prefix — pre-launch (bij ELKE start).
#
# Waarom
#   vkd3d-proton plaatst zijn PSO/SPIR-V-cache (vkd3d-proton.cache +
#   vkd3d-proton.cache.write) standaard in de CWD = de game-installatiemap.
#   Op de NFS-share faalt het wegschrijven van de write-cache
#   ("err:vkd3d-proton:vkd3d_file_map_read_only: Failed to MapViewOfFile for
#   vkd3d-proton.cache.write"), waardoor de cache niet bewaard blijft → extra
#   laadtijd/stutter bij elke start.
#
#   Deze hook verplaatst de cache naar de prefix-map van de gebruiker (lokale
#   home), tenzij VKD3D_SHADER_CACHE_PATH al expliciet gezet is.

hook_run() {
  [ -n "${PREFIX_DIR:-}" ] || { _log "hook(vkd3d-cache-prefix): PREFIX_DIR niet gezet → overslaan."; return 0; }

  if [ -n "${VKD3D_SHADER_CACHE_PATH:-}" ]; then
    _log "hook(vkd3d-cache-prefix): VKD3D_SHADER_CACHE_PATH al gezet ('${VKD3D_SHADER_CACHE_PATH}') → respecteren."
    return 0
  fi

  local dir="$PREFIX_DIR/vkd3d-cache"
  mkdir -p "$dir" 2>/dev/null || { _log "hook(vkd3d-cache-prefix): kon '${dir}' niet aanmaken → overslaan."; return 0; }
  export VKD3D_SHADER_CACHE_PATH="$dir"
  _log "hook(vkd3d-cache-prefix): VKD3D_SHADER_CACHE_PATH='${dir}' (lokaal i.p.v. game-folder)."
}
