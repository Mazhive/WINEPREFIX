#!/bin/bash
# hook: raymanlegends-steam-registry — forceer de Steam-route via HKLM-sleutels.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PRE_LAUNCH_HOOKS=( "raymanlegends_steam_registry" )
#
# Probleem: de game toont een "download Uplay"-menu dat het spel niet verder
# laat. Oorzaak is NIET de gamedir maar de prefix: de werkende prefix
# (movedprefixes/242550) heeft drie HKLM-sleutels die een verse prefix mist:
#
#   HKLM\Software\Wow6432Node\Ubisoft\RaymanLegendsSteam   <- de "Steam-route"
#   HKLM\Software\Wow6432Node\Ubisoft\Launcher
#   HKLM\...\CurrentVersion\Uninstall\Uplay
#
# Zonder die sleutels denkt het spel dat het een Uplay-build is. RaymanLegendsSteam
# bevat exe_path/install_path; de game snijdt daar de bestandsnaam af en plakt er
# gdf.dll achter. Omdat een verse prefix die sleutel mist valt het terug op eigen
# string-werk dat de padscheiding kwijtraakt — in de log zichtbaar als
# "RaymanLegendsgdf.dll" in plaats van "RaymanLegends\gdf.dll".
#
# De map "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher" bestaat in de
# werkende prefix ook al NIET: alleen de registersleutels zijn nodig. Deze hook
# raakt daarom uitsluitend de prefix en laat de gedeelde gamedir ongemoeid.
#
# Bewust PRE_LAUNCH_HOOKS en niet PROVISION_HOOKS: provisioning sloopt over voor
# een bestaande prefix ("Prefix is al geprovisiond"), en dit moet bij elke start
# afgedwongen worden. Idempotent:waarden worden onvoorwaardelijk overschreven.
#
# Terugdraaien: verwijder de sleutels, of haal de hook uit de launcher.

hook_run() {
  local game_dir="${GAME_DIR:?GAME_DIR moet gezet zijn}"
  # Wine-pad: hoe de game het pad ziet. De prefix mapt z: -> /, dus /mnt/... wordt
  # Z:\mnt\... Let op: eerst alle / naar \, dan er Z: voor plakken. De volgorde omdraaien
  # levert Z:mnt/... op (zonder scheiding en met forward slashes).
  local win_dir="Z:${game_dir//\//\\}"

  local steam_key='HKLM\Software\Wow6432Node\Ubisoft\RaymanLegendsSteam'
  local launcher_key='HKLM\Software\Wow6432Node\Ubisoft\Launcher'
  local uninstall_key='HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Uplay'
  local ubi_dir='C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher'

  _reg() { WINEPREFIX="$PREFIX_PATH" wine reg add "$1" /v "$2" /t "$3" /d "$4" /f >/dev/null 2>&1; }

  local fail=0

  # De Steam-route. exe_path wijst naar de ECHTE bestandsnaam (Rayman_Legends.exe,
  # met underscore); de werkende prefix bevat hier per ongeluk de spatie-variant
  # "Rayman Legends.exe", wat de afgeleide gdf.dll-padketen breekt.
  _reg "$steam_key" exe_path     REG_SZ "$win_dir\\Rayman_Legends.exe" || fail=1
  _reg "$steam_key" install_path REG_SZ "$win_dir"                    || fail=1

  # Launcher- en uninstall-traces; de game leest ze als aanwezigheidssignaal.
  _reg "$launcher_key" InstallDir         REG_SZ "$ubi_dir\\" || fail=1
  _reg "$launcher_key" "Installer Language" REG_SZ "1033"      || fail=1
  _reg "$launcher_key" Version            REG_SZ "3877"         || fail=1

  _reg "$uninstall_key" DisplayName          REG_SZ "Uplay"          || fail=1
  _reg "$uninstall_key" DisplayIcon          REG_SZ "$ubi_dir\\Uplay.exe" || fail=1
  _reg "$uninstall_key" DisplayVersion       REG_SZ "4.9"            || fail=1
  _reg "$uninstall_key" InstallLocation      REG_SZ "$ubi_dir\\"     || fail=1
  _reg "$uninstall_key" Publisher             REG_SZ "Ubisoft"        || fail=1
  _reg "$uninstall_key" Version              REG_DWORD "3877"  || fail=1
  _reg "$uninstall_key" VersionMajor          REG_DWORD "4"  || fail=1
  _reg "$uninstall_key" VersionMinor          REG_DWORD "9"  || fail=1

  if [ "$fail" -ne 0 ]; then
    _log "hook(raymanlegends-steam-registry): wine reg add faalde; controleer of wine het juiste pad doet."
    return 1
  fi

  _log "hook(raymanlegends-steam-registry): Steam-route-sleutels gezet (RaymanLegendsSteam, Launcher, Uninstall\\Uplay)."
}