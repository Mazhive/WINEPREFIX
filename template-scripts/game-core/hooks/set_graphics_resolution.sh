#!/usr/bin/env bash
# hook: set_graphics_resolution — Set registry keys for Graphics Width and Height
#
# Module (game-core/hooks/) opgeroepen door game-common.sh via
#   PROVISION_HOOKS=("set_graphics_resolution")
#
# Zet de door Worms World Party Remastered gelezen resolutiesleutels.
# De game leest HKCU\Software\Team17DigitalLTD\WormsWorldParty\Options met
# DisplayXSize/DisplayYSize (REG_DWORD) + DisplaySize (index). Referentiewaarden
# uit een werkende prefix: 1024x768 (4:3), DisplaySize=2, vSync=0.

hook_run() {
  local width="1024"
  local height="768"
  local reg_path="HKEY_CURRENT_USER\Software\Team17DigitalLTD\WormsWorldParty\Options"

  _log "hook(set_graphics_resolution): Setting DisplayXSize=$width, DisplayYSize=$height..."

  # Runner-eigen wine/wineserver gebruiken
  local winecmd wineservercmd
  winecmd="wine"; wineservercmd="wineserver"
  local rbin
  if rbin="$(_runner_wine)"; then
    winecmd="$rbin/wine"; wineservercmd="$rbin/wineserver"
    _log "hook(set_graphics_resolution): runner-wine gebruikt ($winecmd)."
  fi

  # Set DisplayXSize
  WINEPREFIX="$PREFIX_PATH" "$winecmd" reg add "$reg_path" \
    /v "DisplayXSize" /t REG_DWORD /d "$width" /f >/dev/null 2>&1 || \
    _log "hook(set_graphics_resolution): Kon DisplayXSize niet instellen."

  # Set DisplayYSize
  WINEPREFIX="$PREFIX_PATH" "$winecmd" reg add "$reg_path" \
    /v "DisplayYSize" /t REG_DWORD /d "$height" /f >/dev/null 2>&1 || \
    _log "hook(set_graphics_resolution): Kon DisplayYSize niet instellen."

  # Set DisplaySize (index) + vSync, net als de werkende referentie
  WINEPREFIX="$PREFIX_PATH" "$winecmd" reg add "$reg_path" \
    /v "DisplaySize" /t REG_DWORD /d "2" /f >/dev/null 2>&1 || true
  WINEPREFIX="$PREFIX_PATH" "$winecmd" reg add "$reg_path" \
    /v "vSync" /t REG_DWORD /d "0" /f >/dev/null 2>&1 || true

  # Registry flush
  WINEPREFIX="$PREFIX_PATH" "$wineservercmd" -w 2>/dev/null || true

  # Verify
  local out
  out="$(WINEPREFIX="$PREFIX_PATH" "$winecmd" reg query "$reg_path" 2>/dev/null)"
  echo "$out" | grep -E 'DisplayXSize|DisplayYSize|DisplaySize|vSync' | sed 's/^/       [game] /'

  _log "hook(set_graphics_resolution): Klaar."
}