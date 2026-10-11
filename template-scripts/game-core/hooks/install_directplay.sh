#!/bin/bash
# hook: install-directplay — DirectPlay installeren via winetricks.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install-directplay")
# DirectPlay is nodig voor oudere games die netwerk/multiplayer functionaliteit
# gebruiken via DirectPlay (zoals Halo CE).

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _log "hook(install-directplay): winetricks -q directplay..."
    WINEPREFIX="$PREFIX_PATH" winetricks -q directplay || \
      _log "hook(install-directplay): winetricks gaf een non-zero exit; controleer eindstatus."
  else
    _log "hook(install-directplay): winetricks niet gevonden; DirectPlay niet geïnstalleerd."
  fi
}