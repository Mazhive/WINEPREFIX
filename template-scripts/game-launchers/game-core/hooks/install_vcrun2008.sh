#!/bin/bash
# hook: install-vcrun2008 — VC++2008-runtime leveren in de prefix.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install-vcrun2008")
# Levert de VC++ 2008 runtime (msvcr90, msvcp90) via winetricks.

_VC2008_REQUIRED_DLLS=( msvcr90.dll msvcp90.dll )
_VC2008_OVERRIDE_DLLS=( msvcr90 msvcp90 )

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _log "hook(install-vcrun2008): winetricks -q vcrun2008..."
    WINEPREFIX="$PREFIX_PATH" winetricks -q vcrun2008 || \
      _log "hook(install-vcrun2008): winetricks gaf een non-zero exit; controleer eindstatus."
  else
    _log "hook(install-vcrun2008): winetricks niet gevonden; vcrun2008 niet geïnstalleerd."
  fi

  # Overrides zekeren
  local dll
  for dll in "${_VC2008_OVERRIDE_DLLS[@]}"; do
    WINEPREFIX="$PREFIX_PATH" wine reg add "HKCU\\Software\\Wine\\DllOverrides" \
      /v "*$dll" /d native,builtin /f >/dev/null 2>&1 || true
  done
  _log "hook(install-vcrun2008): DllOverrides native,builtin ingesteld."
}