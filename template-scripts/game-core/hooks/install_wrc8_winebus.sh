#!/bin/bash
# hook: install-wrc8-winebus — Zet winebus Enable SDL=0 (hidraw blijft aan).
# Bron: movedprefixes/wrc8 system.reg winebus settings

hook_run() {
  _log "hook(install-wrc8-winebus): winebus Enable SDL=0 instellen..."

  # winebus Enable SDL=0 (hidraw blijft aan) - exact zoals in werkende prefix
  WINEPREFIX="$PREFIX_PATH" wine reg add "HKLM\System\CurrentControlSet\Services\winebus" /v "Enable SDL" /t REG_DWORD /d 0 /f >/dev/null 2>&1 || {
    _log "hook(install-wrc8-winebus): registry update mislukt"
    return 1
  }

  _log "hook(install-wrc8-winebus): Enable SDL=0 ingesteld (hidraw blijft aan)"
  return 0
}
