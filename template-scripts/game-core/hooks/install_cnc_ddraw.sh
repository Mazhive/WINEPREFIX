#!/usr/bin/env bash
# hook: install_cnc_ddraw — Download cnc-ddraw and place ddraw.dll in the game folder
#
# Module (game-core/hooks/) opgeroepen door game-common.sh via
#   PROVISION_HOOKS=("install_cnc_ddraw")
#
# cnc-ddraw is a DirectDraw wrapper that fixes rendering issues in older games
# on modern systems. It provides proper DirectDraw emulation via Direct3D.

hook_run() {
  local game_dir="$GAME_DIR"
  local ddraw_url="https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/v2.1.1.0/cnc-ddraw_v2.1.1.0.zip"
  local temp_dir="/tmp/cnc-ddraw-$$"
  local zip_file="$temp_dir/cnc-ddraw.zip"

  _log "hook(install_cnc_ddraw): Downloading cnc-ddraw..."

  mkdir -p "$temp_dir"

  if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    _log "hook(install_cnc_ddraw): Geen wget of curl gevonden; kan cnc-ddraw niet downloaden."
    return 1
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$zip_file" "$ddraw_url" || {
      _log "hook(install_cnc_ddraw): Download mislukt met wget."
      rm -rf "$temp_dir"
      return 1
    }
  else
    curl -sL -o "$zip_file" "$ddraw_url" || {
      _log "hook(install_cnc_ddraw): Download mislukt met curl."
      rm -rf "$temp_dir"
      return 1
    }
  fi

  _log "hook(install_cnc_ddraw): Uitpakken..."

  if ! command -v unzip >/dev/null 2>&1; then
    _log "hook(install_cnc_ddraw): unzip niet gevonden; kan niet uitpakken."
    rm -rf "$temp_dir"
    return 1
  fi

  unzip -q -o "$zip_file" -d "$temp_dir" || {
    _log "hook(install_cnc_ddraw): Uitpakken mislukt."
    rm -rf "$temp_dir"
    return 1
  }

  # Zoek ddraw.dll in het uitgepakte archief
  local ddraw_dll
  ddraw_dll=$(find "$temp_dir" -name "ddraw.dll" -type f | head -1)

  if [ -z "$ddraw_dll" ]; then
    _log "hook(install_cnc_ddraw): ddraw.dll niet gevonden in archief."
    rm -rf "$temp_dir"
    return 1
  fi

  _log "hook(install_cnc_ddraw): Kopiëren ddraw.dll naar game folder..."

  cp "$ddraw_dll" "$game_dir/ddraw.dll" || {
    _log "hook(install_cnc_ddraw): Kopiëren mislukt."
    rm -rf "$temp_dir"
    return 1
  }

  _log "hook(install_cnc_ddraw): ddraw.dll geplaatst in $game_dir/ddraw.dll"

  # Cleanup
  rm -rf "$temp_dir"

  _log "hook(install_cnc_ddraw): Klaar."
}