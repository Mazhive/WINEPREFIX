#!/bin/bash
# hook: install-wrc8-dlloverrides — Zet exacte DllOverrides van werkende wrc8 prefix.
# Bron: movedprefixes/wrc8/user.reg [Software\Wine\DllOverrides]

hook_run() {
  _log "hook(install-wrc8-dlloverrides): DllOverrides instellen..."

  local overrides=(
    "*api-ms-win-crt-conio-l1-1-0=native,builtin"
    "*api-ms-win-crt-convert-l1-1-0=native,builtin"
    "*api-ms-win-crt-environment-l1-1-0=native,builtin"
    "*api-ms-win-crt-filesystem-l1-1-0=native,builtin"
    "*api-ms-win-crt-heap-l1-1-0=native,builtin"
    "*api-ms-win-crt-locale-l1-1-0=native,builtin"
    "*api-ms-win-crt-math-l1-1-0=native,builtin"
    "*api-ms-win-crt-multibyte-l1-1-0=native,builtin"
    "*api-ms-win-crt-private-l1-1-0=native,builtin"
    "*api-ms-win-crt-process-l1-1-0=native,builtin"
    "*api-ms-win-crt-runtime-l1-1-0=native,builtin"
    "*api-ms-win-crt-stdio-l1-1-0=native,builtin"
    "*api-ms-win-crt-string-l1-1-0=native,builtin"
    "*api-ms-win-crt-time-l1-1-0=native,builtin"
    "*api-ms-win-crt-utility-l1-1-0=native,builtin"
    "*atl140=native,builtin"
    "*concrt140=native,builtin"
    "*d3d10core=native"
    "*d3d11=native"
    "*d3d8=native"
    "*d3d9=native"
    "*d3dcompiler_47=native"
    "*dxgi=native"
    "*msvcp140=native,builtin"
    "*msvcp140_1=native,builtin"
    "*msvcp140_2=native,builtin"
    "*msvcp140_atomic_wait=native,builtin"
    "*msvcp140_codecvt_ids=native,builtin"
    "*ucrtbase=native,builtin"
    "*vcamp140=native,builtin"
    "*vccorlib140=native,builtin"
    "*vcomp140=native,builtin"
    "*vcruntime140=native,builtin"
    "*vcruntime140_1=native,builtin"
  )

  local fail=0
  for ov in "${overrides[@]}"; do
    local dll="${ov%%=*}"
    local val="${ov#*=}"
    WINEPREFIX="$PREFIX_PATH" wine reg add "HKCU\Software\Wine\DllOverrides" /v "$dll" /t REG_SZ /d "$val" /f >/dev/null 2>&1 || fail=1
  done

  if [ "$fail" -ne 0 ]; then
    _log "hook(install-wrc8-dlloverrides): sommige overrides mislukt"
    return 1
  fi

  _log "hook(install-wrc8-dlloverrides): alle DllOverrides ingesteld"
  return 0
}
