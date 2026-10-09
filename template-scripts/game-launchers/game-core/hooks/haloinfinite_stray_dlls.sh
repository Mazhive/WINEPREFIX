#!/bin/bash
# hook: haloinfinite-stray-dlls — pre-launch guard (bij ELKE start).
#
# DLL-zoekorde zet de map van de exe vóór system32. Losse runtime-DLL's naast
# HaloInfinite.exe (bv. een gekopieerde Wine-builtin concrt140.dll) schaduwen
# daardoor de native prefix-DLL en laten de game aborten met
# "unimplemented function concrt140.dll...". Deze guard zet zulke bestanden weg
# naar _dll_backup_wine_builtin/ zodat de native prefix-versie geladen wordt.
# Goedkoop: alleen een stat per DLL-naam.

hook_run() {
  local dll src dst moved=0
  [ -n "${GAME_DIR:-}" ] && [ -d "$GAME_DIR" ] || return 0
  for dll in concrt140.dll msvcp140.dll msvcp140_1.dll msvcp140_2.dll \
             msvcp140_atomic_wait.dll msvcp140_codecvt_ids.dll \
             vcomp140.dll vcruntime140.dll vcruntime140_1.dll; do
    src="$GAME_DIR/$dll"
    [ -f "$src" ] || continue
    dst="$GAME_DIR/_dll_backup_wine_builtin"
    mkdir -p "$dst"
    if mv -f "$src" "$dst/$dll" 2>/dev/null; then
      _log "hook(haloinfinite-stray-dlls): $dll naast de exe weggezet → $dst/."
      moved=1
    else
      _log "hook(haloinfinite-stray-dlls): LET OP — kon $src niet wegzetten."
    fi
  done
  [ "$moved" = "1" ] || _log "hook(haloinfinite-stray-dlls): geen schaduw-DLL's naast de exe."
}
