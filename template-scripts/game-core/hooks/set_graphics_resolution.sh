#!/usr/bin/env bash
# hook: set_graphics_resolution — Set registry keys for Graphics Width and Height
#
# Module (game-core/hooks/) opgeroepen door game-common.sh via
#   PROVISION_HOOKS=("set_graphics_resolution")
#
# Sets the Graphics Width and Height registry keys for Worms World Party Remastered
# to match the monitor resolution (1920x1080).

hook_run() {
  local width="1920"
  local height="1080"
  local reg_path="HKEY_CURRENT_USER\Software\Team17\Worms World Party\Options"

  _log "hook(set_graphics_resolution): Setting Graphics Width=$width, Height=$height..."

  # Runner-eigen wine/wineserver gebruiken
  local winecmd wineservercmd
  winecmd="wine"; wineservercmd="wineserver"
  local rbin
  if rbin="$(_runner_wine)"; then
    winecmd="$rbin/wine"; wineservercmd="$rbin/wineserver"
    _log "hook(set_graphics_resolution): runner-wine gebruikt ($winecmd)."
  fi

  # Set Graphics Width
  WINEPREFIX="$PREFIX_PATH" "$winecmd" reg add "$reg_path" \
    /v "Graphics Width" /t REG_DWORD /d "$width" /f >/dev/null 2>&1 || \
    _log "hook(set_graphics_resolution): Kon Graphics Width niet instellen."

  # Set Graphics Height
  WINEPREFIX="$PREFIX_PATH" "$winecmd" reg add "$reg_path" \
    /v "Graphics Height" /t REG_DWORD /d "$height" /f >/dev/null 2>&1 || \
    _log "hook(set_graphics_resolution): Kon Graphics Height niet instellen."

  # Registry flush
  WINEPREFIX="$PREFIX_PATH" "$wineservercmd" -w 2>/dev/null || true

  # Verify
  local out
  out="$(WINEPREFIX="$PREFIX_PATH" "$winecmd" reg query "$reg_path" 2>/dev/null)"
  echo "$out" | grep -E 'Graphics Width|Graphics Height' | sed 's/^/       [game] /'

  _log "hook(set_graphics_resolution): Klaar."
}