#!/bin/bash
# hook: install-d3dcompiler_47 — D3D Compiler 47 (DirectX 11/12 shader compilation).
# WRC8 en andere moderne DX11/12 games vereisen d3dcompiler_47.

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _log "hook(install-d3dcompiler_47): winetricks -q d3dcompiler_47..."
    WINEPREFIX="$PREFIX_PATH" winetricks -q d3dcompiler_47 || \
      _log "hook(install-d3dcompiler_47): winetricks gaf non-zero exit; controleer eindstatus."
  else
    _log "hook(install-d3dcompiler_47): winetricks niet gevonden; d3dcompiler_47 niet geïnstalleerd."
  fi
}
