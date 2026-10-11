#!/bin/bash
# hook: raymanlegends-vcrun2019 — VC++2015-2019-runtime voor Rayman Legends (32-bit)
#
# WINETRICKS, GEEN DllOverrides-wipe. De werkende referentie 242550/pfx draait
# op de 26 native,builtin-overrides die winetricks zelf zet (api-ms-win-crt-*,
# atl*, msvcp*, msvcr*, ucrtbase, vcomp*, concrt140). De vorige versie van
# deze hook deed 'reg delete ...\DllOverrides /f' en sloopte die allemaal — dat
# was een echte fout, geen opruiming.

_VC_REQUIRED_DLLS=( msvcp140.dll msvcp140_1.dll msvcp140_2.dll \
                    msvcp140_atomic_wait.dll msvcp140_codecvt_ids.dll \
                    vcruntime140.dll vcruntime140_1.dll ucrtbase.dll )

# Rayman is 32-bit, dus de DLL's moeten in de 32-bits map staan. Bij een
# win64-prefix is dat syswow64; bij deze win32-prefix is dat system32.
_vc_dir32() { _prefix_dir_32; }
_vc_is_ok() { _dll_is_x86 "$(_vc_dir32)/$1"; }

_vc_via_winetricks() {
  _log "hook(raymanlegends-vcrun2019): winetricks -q ucrtbase2019 vcrun2019..."
  # winetricks bepaalt zijn eigen architectuur uit het bestaan van syswow64
  # (winetricks:4419) en zet daarom automatisch de juiste x32/x64-set.
  WINEPREFIX="$PREFIX_PATH" winetricks -q ucrtbase2019 vcrun2019 || \
    _log "hook(raymanlegends-vcrun2019): winetricks gaf een non-zero exit; controleer eindstatus."
}

_vc_via_redist() {
  local redist
  redist="$(find "$GAME_DIR/_CommonRedist" -iname 'VC_redist.x64.exe' -print -quit 2>/dev/null)"
  if [ -n "$redist" ]; then
    _log "hook(raymanlegends-vcrun2019): gebundelde redist installeren: $(basename "$redist")"
    WINEPREFIX="$PREFIX_PATH" wine "$redist" /install /quiet /norestart || \
      _log "hook(raymanlegends-vcrun2019): redist gaf een non-zero exit."
    VC_METHOD=redist
  else
    _log "hook(raymanlegends-vcrun2019): geen VC_redist.x64.exe in $GAME_DIR/_CommonRedist."
    VC_METHOD=none
  fi
}

# Herstelt ontbrekende/ongeldige DLL's. Let op: herstelbron moet dezelfde
# architectuur leveren als de map waarin we schrijven. Vóór deze fix stond
# hier _proton_builtin_dll zonder arch-argument, dus altijd x64 — daarmee
# werden correcte x86-DLL's overschreven (1843959 bytes = GE-Proton10-34
# x86_64-windows/msvcp140.dll).
_vc_heal() {
  local dll src bad=0 miss=""
  local dir32; dir32="$(_vc_dir32)"
  for dll in "${_VC_REQUIRED_DLLS[@]}"; do
    if _vc_is_ok "$dll"; then
      continue
    fi
    [ -f "$dir32/$dll" ] && _log "hook(raymanlegends-vcrun2019): $dll geen geldige 32-bits PE — heal."
    if src="$(_runtime_dll_source "$dll" x86)" || src="$(_proton_builtin_dll "$dll" x86)"; then
      if cp -f "$src" "$dir32/$dll" 2>/dev/null; then
        chmod u+w "$dir32/$dll" 2>/dev/null || true
        _log "hook(raymanlegends-vcrun2019): $dll hersteld als 32-bits."
      else
        bad=1; miss="$miss $dll"
      fi
    else
      bad=1; miss="$miss $dll"
    fi
  done
  [ "$bad" = "1" ] && _log "hook(raymanlegends-vcrun2019): ontbrekend/ongeldig na heal:$miss"
  return $bad
}

hook_run() {
  local method="${VC_RUNTIME_METHOD:-winetricks}"
  VC_METHOD=""

  if [ "$method" = "redist" ]; then
    _vc_via_redist
  elif command -v winetricks >/dev/null 2>&1; then
    _vc_via_winetricks
    VC_METHOD=winetricks
  else
    _vc_via_redist
  fi

  WINEPREFIX="$PREFIX_PATH" winecfg -v "${VC_RUNTIME_WINVER:-win10}" >/dev/null 2>&1 || true
  _log "hook(raymanlegends-vcrun2019): Windows-versie hersteld naar ${VC_RUNTIME_WINVER:-win10}."

  # Eerst één keer valideren. Niet automatisch opnieuw healen: als de
  # winetricks-uitkomst afwijkt is een tweede installatie zelden de oplossing
  # en overschrijven zou de fout verhullen in plaats van hem te tonen.
  if ! _vc_heal; then
    if [ "$VC_METHOD" != "winetricks" ] && command -v winetricks >/dev/null 2>&1; then
      _log "hook(raymanlegends-vcrun2019): vangnet — winetricks vcrun2019."
      WINEPREFIX="$PREFIX_PATH" winetricks -q vcrun2019 || true
      _vc_heal
    fi
  fi

  local dir32; dir32="$(_vc_dir32)"
  local dll ok=1
  for dll in "${_VC_REQUIRED_DLLS[@]}"; do
    if ! _vc_is_ok "$dll"; then
      ok=0
      _log "hook(raymanlegends-vcrun2019): MISS $dll in $dir32"
    fi
  done
  if [ "$ok" = "1" ]; then
    _log "hook(raymanlegends-vcrun2019): VC-runtime volledig en geldig als 32-bits (method=$VC_METHOD)."
  else
    _log "hook(raymanlegends-vcrun2019): LET OP — VC-runtime niet volledig."
  fi
}
