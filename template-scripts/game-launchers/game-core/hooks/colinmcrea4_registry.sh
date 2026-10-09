#!/bin/bash
# hook: colinmcrea4-registry — zet CMR4's eigen installatieconfig in het register.
#
# Module (game-core/hooks/) die door game-common.sh wordt opgeroepen via
#   PRE_LAUNCH_HOOKS=( "colinmcrea4_virtual_desktop" "colinmcrea4_registry" )
#
# Probleem
#   Een verse gebouwde CMR4-prefix crasht direct: page fault op 0x00000000 in
#   32-bit code, EIP 0x0052435a = "movl (%edi),%ecx" met EDI=0. Op de stack
#   staat de string "fonts\HelNu_10.dds" — de NULL komt uit het laden van een
#   font-atlas.
#
#   CMR4 kan die NULL niet zelf oplossen. Het is een InstallShield-titel uit 2004
#   die zijn eigen locatie UIT HET REGISTER leest en die sleutel niet aanmaakt op
#   een schone prefix. Alle vier de werkende prefixen hebben wél die sleutel:
#
#     movedprefixes/Collinmcrea4/pfx          CurrentVersion 6.1/7601 + sleutel
#     movedprefixes/Collinmcrea4/pfx.djuga    CurrentVersion 6.1/7601 + sleutel
#     movedprefixes/Collinmcrea4/pfx.noa      CurrentVersion 6.1/7601 + sleutel
#     movedprefixes/Collinmcrea4 (copy)       CurrentVersion 6.1/7601 + sleutel
#
#     HKLM\Software\Codemasters\Colin McRae Rally 04
#       "INSTALL_PATH" / "CD_PATH" / "VIDEO_PATH" / "AUDIO_PATH" -> Z:\...\Colinmcrea4
#
#   De prefix die de launcher zelf bouwt mist die sleutel, en dan crasht de game.
#   De prefix-map ~/GAMEPREFIXES/ColinMcRae4/pfx is de productie-prefix.
#
# Waarom PRE_LAUNCH_HOOKS en niet PROVISION_HOOKS
#   CMR4 overschrijft deze sleutel zelf bij het afsluiten. Alleen tijdens het
#   provisionen schrijven zou bij elke volgende start weer een sleutel met een
#   locatie van een andere machine achterlaten. Daarom bij elke start afdwingen;
#   de waarden worden onvoorwaardelijk overschreven, dus de hook is idempotent.
#
# Eigen flush — niet overgenomen uit een andere game, maar nodig voor deze
#   In game_main() draaien de PRE_HOOKS direct vóór game_launch(), zonder
#   wineserver -w ertussen. CMR4 leest zijn configuratie bij startup van het
#   register, dus deze hook flusht zelf. timeout 10 is een scope, net als in
#   game_main(): een blokkerende w-w op een willekeurige wineserver van een
#   andere game zou de launch ophangen.
#
# Bewust NIET weggeschreven
#   ADAPTER_VID / ADAPTER_PID   machine-specifiek; de referentie had AMD
#                               0x1002 / 0x68d8. De game leest de adapter zelf uit.
#   Width / Height              de referentie had 1440x1080, maar hook
#                               colinmcrea4_video_config legt het scherm vast
#                               op 1280x960 (2x integer van 640x480). Vastzetten
#                               in het register zou die keuze tegenspreken.
#   Gamma / ZDepth / SHADERS / FSAA / BitDepth / SPEC_SELECTION1..3
#                               videoderivaten die de game zelf uit de adapter
#                               haalt; vastzetten maskeert een echte afwijking.
#
# Terugdraaien
#   Haal "colinmcrea4_registry" uit PRE_LAUNCH_HOOKS in colinmcrea4.sh, of
#   verwijder de sleutel:
#     WINEPREFIX=~/GAMEPREFIXES/ColinMcRae4/pfx \
#       wine reg delete 'HKLM\Software\Codemasters\Colin McRae Rally 04' /f

hook_run() {
  local game_dir="${GAME_DIR:?GAME_DIR moet gezet zijn}"
  # Wine-pad: de prefix koppelt z: aan /, dus /mnt/... wordt Z:\mnt\....
  # Eerst alle / naar \, dan Z: ervoor plakken; anders mist de scheiding.
  local win_dir="Z:${game_dir//\//\\}"
  local disc_msg="Please insert disk 1/4 of Colin McRae Rally 04"

  local key='HKLM\Software\Codemasters\Colin McRae Rally 04'
  local ver_key="$key\\1.00.000"

  _reg() { WINEPREFIX="$PREFIX_PATH" wine reg add "$1" /v "$2" /t "$3" /d "$4" /f >/dev/null 2>&1; }

  local fail=0

  # De vier locatie-paden. Dit is de kern van de fix: zonder deze heeft de game
  # geen basis-map om zijn Data/ en fonts/ bij te zoeken.
  _reg "$key" INSTALL_PATH REG_SZ "$win_dir" || fail=1
  _reg "$key" CD_PATH      REG_SZ "$win_dir" || fail=1
  _reg "$key" VIDEO_PATH   REG_SZ "$win_dir" || fail=1
  _reg "$key" AUDIO_PATH   REG_SZ "$win_dir" || fail=1

  # De schijf-prompts. CMR4 toont deze als hij meent dat hij niet geïnstalleerd is.
  _reg "$key" NO_DISC    REG_SZ "$disc_msg" || fail=1
  _reg "$key" NO_DRIVE   REG_SZ "$disc_msg" || fail=1
  _reg "$key" WRONG_DISC REG_SZ "$disc_msg" || fail=1

  # Taal (Engels) en de rechten-check die CMR4 bij startup doet.
  _reg "$key" LANGUAGE     REG_SZ "E"                        || fail=1
  _reg "$key" ADMIN_RIGHTS REG_SZ "No administrator rights."  || fail=1

  # De versie-tak. Leeg in de referentie; hij bestaat daar, dus CMR4 verwacht hem.
  WINEPREFIX="$PREFIX_PATH" wine reg add "$ver_key" /f >/dev/null 2>&1 || fail=1

  if [ "$fail" -ne 0 ]; then
    _log "hook(colinmcrea4-registry): wine reg add faalde; CMR4 blijft zonder installatiepad en crasht."
    return 1
  fi

  # Flush: tussen deze hook en game_launch() zit geen wineserver -w.
  timeout 10 env WINEPREFIX="$PREFIX_PATH" wineserver -w 2>/dev/null || true

  _log "hook(colinmcrea4-registry): CMR4-installatiepad gezet op $win_dir"
}