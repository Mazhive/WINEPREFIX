#!/bin/bash
# hook: raymanlegends-dxvk-nocfg — GEPARKEERD, NIET AANROEPEN (2026-10)
#
# Waarom deze hook uit PROVISION_HOOKS is gehaald:
#
# 1. ARCHITECTUURFOUT. Deze hook kopieerde d3d11/dxgi/d3d9 uit de
#    system32 van de referentie-prefix. Die zijn daar x86-64. Rayman
#    draait in een win32-prefix, waar system32 de 32-bits map ís. Er
#    kwamen dus drie x64-DLL's in een 32-bits map terecht.
# 2. HUISREGEL. Er wordt nooit een bestaande prefix gekopieerd, en nooit
#    vanaf de NFS-share; referentie-prefixen zijn een meetlat, geen
#    sjabloon.
# 3. NIET BEWEZEN NODIG. Rayman is D3D9/D3D11 en kan op wined3d draaien
#    (zoals 'The Chaos Engine Remastered' op deze machine).
#
# Wil je DXVK later echt terug, gebruik dan 'winetricks -q dxvk' in plaats
# van een kopie: die zet zelf de juiste x32/x64-set in de juiste map. Let
# op dat winetricks daarbij wél DllOverrides zet (dxgi,d3d8,d3d9,
# d3d10core,d3d11 -> native); de referentie 242550 heeft die juist niet.
hook_run() {
  _log "hook(raymanlegends-dxvk-nocfg): geparkeerd — doet niets."
  return 0
}
