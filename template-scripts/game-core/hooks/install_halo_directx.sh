#!/bin/bash
# hook: install-halo-directx — Halo's eigen DirectX installer draaien.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install-halo-directx")
# Draait dxsetup.exe uit de game-map voor correcte DirectX 9.0b installatie.

hook_run() {
  local dxsetup="$GAME_DIR/DirectX/dxsetup.exe"
  if [ -f "$dxsetup" ]; then
    _log "hook(install-halo-directx): DirectX installer draaien..."
    WINEPREFIX="$PREFIX_PATH" wine "$dxsetup" /silent /norestart || \
      _log "hook(install-halo-directx): dxsetup.exe gaf non-zero exit."
    _log "hook(install-halo-directx): DirectX installer voltooid."
  else
    _log "hook(install-halo-directx): geen dxsetup.exe gevonden in $GAME_DIR/DirectX/"
  fi
}