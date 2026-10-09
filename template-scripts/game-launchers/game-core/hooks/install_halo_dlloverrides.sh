#!/bin/bash
# hook: install-halo-dlloverrides — DLL overrides voor Halo CE.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install-halo-dlloverrides")
# Halo CE werkt beter met native d3d9 en dxgi (via DXVK).

hook_run() {
  _log "hook(install-halo-dlloverrides): DLL overrides instellen..."
  local dll
  for dll in d3d9 dxgi; do
    WINEPREFIX="$PREFIX_PATH" wine reg add "HKCU\\Software\\Wine\\DllOverrides" \
      /v "*$dll" /d native,builtin /f >/dev/null 2>&1 || true
  done
  _log "hook(install-halo-dlloverrides): d3d9, dxgi native,builtin ingesteld."
}