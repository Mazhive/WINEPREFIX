#!/bin/bash
# hook: install-wrc8-deps — Installeer WRC8-specifieke dependencies via winetricks.
# vcrun2019: VC++ 2015-2019 runtime (vcruntime140, msvcp140, etc. - zoals in werkende prefix)
# d3dcompiler_47: D3D compiler 47 (DirectX 11/12 shader compilation)

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _log "hook(install-wrc8-deps): winetricks -q vcrun2019 d3dcompiler_47..."
    WINEPREFIX="$PREFIX_PATH" winetricks -q vcrun2019 d3dcompiler_47 || \
      _log "hook(install-wrc8-deps): winetricks gaf non-zero exit; check handmatig."
  else
    _log "hook(install-wrc8-deps): winetricks niet gevonden; dependencies niet geïnstalleerd."
  fi
}
