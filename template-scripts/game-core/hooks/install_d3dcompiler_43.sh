#!/bin/bash
# hook: install-d3dcompiler_43 — D3D Compiler 43 (DirectX 10/11 shader compilation).
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install_d3dcompiler_43")
# Recept uit de werkende one-liner voor Myst 2021 Remake: de game importeert
# d3dcompiler_43 direct; winetricks levert de native DLL in system32.

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _log "hook(install-d3dcompiler_43): winetricks -q d3dcompiler_43..."
    WINEPREFIX="$PREFIX_PATH" winetricks -q d3dcompiler_43 || \
      _log "hook(install-d3dcompiler_43): winetricks gaf non-zero exit; controleer eindstatus."
  else
    _log "hook(install-d3dcompiler_43): winetricks niet gevonden; d3dcompiler_43 niet geïnstalleerd."
  fi
}