#!/bin/bash
# Colin McRae Rally 04 — Wine launcher via game-common.sh core
# Codemasters, 32-bit (2004). DirectX 9 game.
#
# Recept (afgeleid uit de referentie-prefix, alleen als ANALYSE gebruikt):
#   plain wine + PREFIX_ARCH=win32 + DXVK + d3dx9 + Windows 7.
#   De referentie-prefix (movedprefixes/Collinmcrea4/pfx) draait CurrentVersion
#   6.1 / build 7601 (Windows 7 SP1) — zie GuideLineLauncher.md.
#
# PROVISION_HOOKS — waarom elk van deze drie:
#   install_win7     wineboot -i (in _provision_fresh, game-common.sh) zet een
#                    verse prefix ALTIJD op Windows 10 (19045). Alle vier de
#                    werkende prefixen draaien 6.1/7601, dus terug naar win7.
#   install_dxvk     De referentie-prefix draaide NIET op wined3d: de
#                    winetricks.log noemt dxvk93 en system32 bevat de native
#                    DXVK-dll's (d3d9.dll 1,73 MB / dxgi.dll 1,68 MB /
#                    d3d11.dll 2,48 MB / d3d10core.dll 1,01 MB). Zonder DXVK
#                    blijft de game op wined3d en crasht hij: de page fault op
#                    0x0052435a valt samen met het mislukken van het laden van
#                    een font-atlas (wined3d: "fonts\HelNu_10.dds" op de stack).
#                    Let op: hier isbewust de HUIDIGE dxvk gekozen, niet dxvk93 —
#                    0.9.3 is van 2017 en voorkomt de Vulkan van wine-11.0 niet.
#   install_d3dx9    De referentie had d3dx9_43 / d3dx10_43 / d3dx11_43.
#                    CMR4 is D3D9, dus de d3dx9-familie is de relevante.
#
# Geen VC++/redist-hook: de gamemap heeft geen _CommonRedist, het is een D3D9-titel
# uit 2004 en de werkende prefix heeft geen vcrun2019. Ook geen dgVoodoo2: de
# werkende prefix heeft die niet. Let op dat hook colinmcrea4_vcrun2019.sh
# bovendien eindigt op 'winecfg -v winxp' en dus install_win7 zou omzetten — hij
# hoort daarom niet in deze launcher.
#
# PRE_LAUNCH_HOOKS — colinmcrea4_registry is de Crash-fix, zie die hook voor de
#   volledige onderbouwing. Kort: CMR4 leest zijn installatiepad uit
#   HKLM\Software\Codemasters\Colin McRae Rally 04 en maakt die sleutel op een
#   schone prefix niet zelf aan. Zonder die sleutel crasht de game op 0x0052435a.

export GAME_NAME="ColinMcRae4"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Colinmcrea4"
export GAME_EXE="$GAME_DIR/cmr4.exe"
export PREFIX_ARCH="win32"          # 32-bit prefix zoals origineel werkende prefix
export SCRIPT_VERSION="3"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"
export GAME_DISPLAY_NAME="Colin McRae Rally 04"
export GAME_ICON="ColinMcRaeRally04.png"

export STEAM_APPID="27660"

# Genest scherm via gamescope, 1280x960. Dit is de combinatie die werkt: CMR4
# (D3D9, 640x480 native) krijgt een buffer die 2x zo groot is, en gamescope
# schaalt die integer naar het scherm. game-common.sh bouwt hieruit
# `gamescope -f -W 1280 -H 960 --`; colinmcrea4_video_config zet dezelfde waarden
# nogmaals, zodat de launcher ook na een losse hook-run dezelfde schermgrootte
# houdt. Alleen actief op een Wayland-sessie met gamescope aanwezig; anders
# logt game-common.sh en start de game gewoon.
export GAME_GAMESCOPE="1"
export GAME_GAMESCOPE_RES="1280x960"

# Provisioning: Windows 7 + DXVK + d3dx9, alle drie in de werkende referentie
# teruggevonden. Onderbouwing in de commentaar hierboven.
PROVISION_HOOKS=("install_win7" "install_dxvk" "install_d3dx9")

# Pre-launch hooks (bij elke start)
# colinmcrea4_video_config: zet GAME_GAMESCOPE + GAME_GAMESCOPE_RES, zodat de
#                           launch in een genest 1280x960-scherm (2x integer
#                           van de 640x480-native) draait. Onder XWayland werkt
#                           de Wine virtual desktop niet: die krijgt daar de
#                           schermgrootte en CMR4's fullscreen-vraag loopt vast.
# colinmcrea4_registry:      zet INSTALL_PATH/CD_PATH/VIDEO_PATH/AUDIO_PATH in
#                           HKLM\Software\Codemasters\Colin McRae Rally 04.
#                           Zonder deze sleutel crasht de game op 0x0052435a.
PRE_LAUNCH_HOOKS=("colinmcrea4_video_config" "colinmcrea4_registry")

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"