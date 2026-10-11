#!/bin/bash
# hook: install-vcrun2022 — VC++2022 runtime leveren in de prefix.
# VC++ 2022 runtime (vcruntime140_1, msvcp140_1/2, etc.) — nieuwere runtime.

_VC2022_REQUIRED_DLLS=( msvcp140_1.dll msvcp140_2.dll msvcp140_atomic_wait.dll \
                        msvcp140_codecvt_ids.dll vcruntime140_1.dll )
_VC2022_OVERRIDE_DLLS=( msvcp140_1 msvcp140_2 msvcp140_atomic_wait \
                        msvcp140_codecvt_ids vcruntime140_1 )

_vc2022_via_winetricks() {
  _log "hook(install-vcrun2022): winetricks -q vcrun2022..."
  WINEPREFIX="$PREFIX_PATH" winetricks -q vcrun2022 || \
    _log "hook(install-vcrun2022): winetricks gaf non-zero exit."
}

_vc2022_set_overrides() {
  local dll
  for dll in "${_VC2022_OVERRIDE_DLLS[@]}"; do
    WINEPREFIX="$PREFIX_PATH" wine reg add "HKCU\\Software\\Wine\\DllOverrides" \
      /v "*$dll" /d native,builtin /f >/dev/null 2>&1 || true
  done
  _log "hook(install-vcrun2022): DllOverrides native,builtin ingesteld."
}

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _vc2022_via_winetricks
  else
    _log "hook(install-vcrun2022): winetricks niet gevonden."
    return 1
  fi
  _vc2022_set_overrides
  _log "hook(install-vcrun2022): VC++2022 runtime ingesteld."
}
