#!/bin/bash
# hook: install-halo-winver-xp — Windows versie op XP zetten voor Halo CE.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install-halo-winver-xp")
# Halo CE (2003) detecteert hardware correcter op Windows XP/2000.

hook_run() {
  _log "hook(install-halo-winver-xp): Windows versie instellen op winxp..."
  WINEPREFIX="$PREFIX_PATH" winecfg -v winxp >/dev/null 2>&1 || \
    _log "hook(install-halo-winver-xp): winecfg kon niet worden uitgevoerd."
  _log "hook(install-halo-winver-xp): Windows versie ingesteld op winxp."
}