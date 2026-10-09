#!/bin/bash
# hook: install-halo-dxvk-conf — dxvk.conf naar prefix kopiëren voor Halo CE.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install-halo-dxvk-conf")
# Kopieert de game-specifieke dxvk.conf naar de prefix drive_c.

hook_run() {
  local src_conf="$GAME_DIR/dxvk.conf"
  local dst_conf="$PREFIX_PATH/drive_c/dxvk.conf"

  if [ -f "$src_conf" ]; then
    _log "hook(install-halo-dxvk-conf): dxvk.conf kopiëren naar prefix..."
    cp -f "$src_conf" "$dst_conf" || \
      _log "hook(install-halo-dxvk-conf): kopiëren mislukt."
    _log "hook(install-halo-dxvk-conf): dxvk.conf gekopieerd naar $dst_conf"
  else
    _log "hook(install-halo-dxvk-conf): geen dxvk.conf gevonden in $GAME_DIR"
  fi
}