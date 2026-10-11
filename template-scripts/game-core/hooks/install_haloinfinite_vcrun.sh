#!/bin/bash
# hook: install-haloinfinite-vcrun — VC++-runtime voor Halo Infinite.
#
# Module (game-core/hooks/) opgeroepen door game-common.sh via
#   PROVISION_HOOKS=("install_haloinfinite_vcrun")
#
# Waarom een eigen hook (niet install_vcrun2022):
#  * Wine's builtin concrt140.dll mist o.a. de constructor
#    ??0_Concurrent_queue_iterator_base_v4@details@Concurrency@@... die de game
#    bij init aanroept → "wine: Call ... to unimplemented function
#    concrt140.dll..." → abort. Er moet dus écht een NATIVE MS-DLL staan.
#  * Een losse concrt140.dll/msvcp140.dll NAST de exe (game-map) heeft
#    DLL-zoekprioriteit en schaduwt de prefix; die zetten we weg naar
#    _dll_backup_wine_builtin/ (reversibel).
#  * De overrides moeten de hele MSVC-set dekken, inclusief concrt140/vcomp140.
#
# NIET gebruiken als heal-bron: _runtime_dll_source/_proton_builtin_dll. In een
# GE-Proton-runner zijn die (default_pfx) symlinks naar Wine's builtins — dus
# juist de stub-concrt140 die dit probleem veroorzaakt.
#
# Levering (VC_RUNTIME_METHOD; default "winetricks"):
#   winetricks → winetricks -q vcrun2022 (referentie-receptuur).
#   redist     → gebundelde $GAME_DIR/_CommonRedist/vcredist/2019/VC_redist.x64.exe
#                (/install /quiet /norestart); winetricks als vangnet.
# Lukt de ene methode niet, dan probeert de andere als vangnet en valideert opnieuw.

HI_REQUIRED_DLLS=( concrt140.dll msvcp140.dll msvcp140_1.dll msvcp140_2.dll \
                   msvcp140_atomic_wait.dll msvcp140_codecvt_ids.dll \
                   vcomp140.dll vcruntime140.dll vcruntime140_1.dll )
HI_OVERRIDE_DLLS=( concrt140 msvcp140 msvcp140_1 msvcp140_2 \
                   msvcp140_atomic_wait msvcp140_codecvt_ids \
                   vcomp140 vcruntime140 vcruntime140_1 )

_hi_stray_dir() { echo "$GAME_DIR/_dll_backup_wine_builtin"; }

# Losse runtime-DLL's naast de exe wegzetten. Zonder dit wint de game-map het
# van system32 en laadt alsnog de kapotte (Wine-)DLL.
_hi_move_stray_game_dlls() {
  local dll src dst
  [ -n "${GAME_DIR:-}" ] && [ -d "$GAME_DIR" ] || return 0
  for dll in "${HI_REQUIRED_DLLS[@]}"; do
    src="$GAME_DIR/$dll"
    [ -f "$src" ] || continue
    dst="$(_hi_stray_dir)"
    mkdir -p "$dst"
    if mv -f "$src" "$dst/$dll" 2>/dev/null; then
      _log "hook(install-haloinfinite-vcrun): $dll stond naast de exe (schaduwt prefix) → $dst/."
    else
      _log "hook(install-haloinfinite-vcrun): LET OP — kon $src niet wegzetten."
    fi
  done
}

_hi_via_winetricks() {
  command -v winetricks >/dev/null 2>&1 || return 1
  _log "hook(install-haloinfinite-vcrun): winetricks -q vcrun2022..."
  WINEPREFIX="$PREFIX_PATH" winetricks -q vcrun2022 || \
    _log "hook(install-haloinfinite-vcrun): winetricks gaf non-zero exit; controleer eindstatus."
  return 0
}

_hi_via_redist() {
  local redist
  redist="$(find "$GAME_DIR/_CommonRedist" -iname 'vc_redist.x64.exe' -print -quit 2>/dev/null)"
  [ -n "$redist" ] || { _log "hook(install-haloinfinite-vcrun): geen VC_redist.x64.exe in $GAME_DIR/_CommonRedist."; return 1; }
  _log "hook(install-haloinfinite-vcrun): gebundelde redist installeren: $(basename "$redist")"
  WINEPREFIX="$PREFIX_PATH" wine "$redist" /install /quiet /norestart || \
    _log "hook(install-haloinfinite-vcrun): redist gaf non-zero exit; vangnet volgt."
  return 0
}

_hi_set_overrides() {
  local dll val
  for dll in "${HI_OVERRIDE_DLLS[@]}"; do
    # concrt140 puur native: Wine's builtin is bewezen kapot voor deze game, dus
    # liever een luide laadfout dan stilletjes terugvallen op de stub.
    [ "$dll" = "concrt140" ] && val=native || val=native,builtin
    WINEPREFIX="$PREFIX_PATH" wine reg add "HKCU\\Software\\Wine\\DllOverrides" \
      /v "*$dll" /d "$val" /f >/dev/null 2>&1 || true
  done
  _log "hook(install-haloinfinite-vcrun): DllOverrides ingesteld (concrt140=native, rest native,builtin)."
}

# Zijn alle vereiste runtime-DLL's aanwezig als x86_64-PE in system32?
_hi_validate() {
  local sys32="$PREFIX_PATH/drive_c/windows/system32" dll bad=0
  for dll in "${HI_REQUIRED_DLLS[@]}"; do
    _dll_is_x86_64 "$sys32/$dll" || { bad=1; _log "hook(install-haloinfinite-vcrun): MISS $dll (ontbreekt of geen x86_64-PE)."; }
  done
  return $bad
}

hook_run() {
  local method="${VC_RUNTIME_METHOD:-winetricks}" primary=0

  _hi_move_stray_game_dlls

  # ── 1. Runtime leveren ───────────────────────────────────
  if [ "$method" = "redist" ]; then
    _hi_via_redist && primary=1
  else
    _hi_via_winetricks && primary=1
  fi
  [ "$primary" = "1" ] || _hi_via_redist || _hi_via_winetricks || true

  # ── 2. Overrides + Windows-versie (Halo Infinite = win10) ─
  _hi_set_overrides
  WINEPREFIX="$PREFIX_PATH" winecfg -v win10 >/dev/null 2>&1 || true

  # ── 3. Valideren; vangnet met de andere methode ──────────
  if ! _hi_validate; then
    if [ "$method" = "winetricks" ]; then
      _log "hook(install-haloinfinite-vcrun): vangnet — gebundelde redist."
      _hi_via_redist || true
    else
      _log "hook(install-haloinfinite-vcrun): vangnet — winetricks vcrun2022."
      _hi_via_winetricks || true
    fi
    _hi_validate || true
  fi

  if _hi_validate; then
    _log "hook(install-haloinfinite-vcrun): MSVC-runtime volledig en geldig."
  else
    _log "hook(install-haloinfinite-vcrun): LET OP — MSVC-runtime niet volledig; game kan aborten op concrt140.dll."
  fi
}
