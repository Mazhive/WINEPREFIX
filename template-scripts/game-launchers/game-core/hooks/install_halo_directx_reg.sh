#!/bin/bash
# hook: install-halo-directx-reg — DirectX versie registerkey voor Halo CE.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PROVISION_HOOKS=("install-halo-directx-reg")
# Halo CE vereist DirectX 9.0b (versie 4.09.00.0900) in de registry.

hook_run() {
  _log "hook(install-halo-directx-reg): DirectX versie registerkey instellen..."
  WINEPREFIX="$PREFIX_PATH" wine reg add "HKLM\\Software\\Microsoft\\DirectX" \
    /v "DirectXVersion" /t REG_SZ /d "4.09.00.0900" /f >/dev/null 2>&1 || \
    _log "hook(install-halo-directx-reg): registerkey kon niet worden ingesteld."
  _log "hook(install-halo-directx-reg): DirectXVersion=4.09.00.0900 ingesteld."
}