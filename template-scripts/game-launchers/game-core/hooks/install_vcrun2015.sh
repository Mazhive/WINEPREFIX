#!/bin/bash
# hook: install-vcrun2015 — VC++2015 runtime leveren in de prefix (32-bit + 64-bit).
# VC++ 2015 runtime (vcruntime140, msvcp140, ucrtbase) — subset van vcrun2019.

_VC2015_REQUIRED_DLLS=( msvcp140.dll vcruntime140.dll ucrtbase.dll )
_VC2015_OVERRIDE_DLLS=( msvcp140 vcruntime140 ucrtbase )

_vc2015_via_winetricks() {
  _log "hook(install-vcrun2015): winetricks -q vcrun2015..."
  WINEPREFIX="$PREFIX_PATH" winetricks -q vcrun2015 || \
    _log "hook(install-vcrun2015): winetricks gaf non-zero exit."
}

_vc2015_set_overrides() {
  local dll
  for dll in "${_VC2015_OVERRIDE_DLLS[@]}"; do
    WINEPREFIX="$PREFIX_PATH" wine reg add "HKCU\\Software\\Wine\\DllOverrides" \
      /v "*$dll" /d native,builtin /f >/dev/null 2>&1 || true
  done
  _log "hook(install-vcrun2015): DllOverrides native,builtin ingesteld."
}

_vc2015_heal() {
  local sys32="$PREFIX_PATH/drive_c/windows/system32"
  local syswow64="$PREFIX_PATH/drive_c/windows/syswow64"
  local dll src bad=0 miss=""
  for dll in "${_VC2015_REQUIRED_DLLS[@]}"; do
    # Check 64-bit in system32
    if [ -f "$sys32/$dll" ] && _dll_is_x86_64 "$sys32/$dll"; then
      continue
    fi
    [ -f "$sys32/$dll" ] && _log "hook(install-vcrun2015): $dll in system32 geen x86_64-PE — heal."
    # Try to get 64-bit from winetricks cache or proton
    if src="$(_runtime_dll_source "$dll")" || src="$(_proton_builtin_dll "$dll")"; then
      if cp -f "$src" "$sys32/$dll" 2>/dev/null; then
        chmod u+w "$sys32/$dll" 2>/dev/null || true
        _log "hook(install-vcrun2015): $dll hersteld als x86_64 in system32."
      else
        bad=1; miss="$miss $dll"
      fi
    else
      bad=1; miss="$miss $dll"
    fi
  done
  [ "$bad" = "1" ] && _log "hook(install-vcrun2015): ontbrekend/ongeldig na heal:$miss"
  return $bad
}

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _log "hook(install-vcrun2015): winetricks -q vcrun2015..."
    WINEPREFIX="$PREFIX_PATH" winetricks -q vcrun2015 || \
      _log "hook(install-vcrun2015): winetricks gaf non-zero exit."
  else
    _log "hook(install-vcrun2015): winetricks niet gevonden."
    return 1
  fi
  _vc2015_set_overrides
  _vc2015_heal
  _log "hook(install-vcrun2015): VC++2015 runtime ingesteld."
}
