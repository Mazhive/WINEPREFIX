# BEVINDINGEN — Cities: Skylines

Werkmethode: `WERKWIJZE.md`.
Launcher: `template-scripts/game-launchers/LINUXLAUNCHERS/citiesskylines.sh`.
Game: non-Steam-map `WINDOWSGAMES/Cities-Skylines-none-Steam` (1.11.1-f2, MEX-crack,
AllDLC, DX11/Unity Mono). Steam-appid 255710. Verse prefix `~/GAMEPREFIXES/CitiesSkylines/`.

## Symptoom

- Op de **NVIDIA/GTX-1070-machine** start de game direct.
- Op de **AMD/Wayland-machine**: zwarte spinner, het venster kwam niet naar voren, en
  gamescope patchte het interne beeld naar 720p.

## Oorzaak

- **Present/focus-stall** bij XWayland + AMD/RADV + DXVK **exclusive fullscreen**
  (`Exclusive FS: 1` in de DXVK-log). De swapchain presenteert wel, maar focus/present
  komt niet betrouwbaar naar voren. NVIDIA had dit niet.
- **720p-patch**: gamescope koos zelf een lage mode toen de interne resolutie niet werd
  meegegeven (edid-patch → blokkerig/laag beeld).
- **Shader-compile-piek**: zonder parallelle compilatie piekte de shader-compile vóór tot
  ~195% CPU gedurende minuten.

## Fix

Launcher `citiesskylines.sh` (`SCRIPT_VERSION=2`, `PROTON_ENABLED=1`, `PROTON_PIN=GE-Proton11-7`,
`STEAM_APPID=255710`, `PROVISION_HOOKS=(install_gamescope)`):

- **`GAME_GAMESCOPE=1`** → gamescope-wrap (nested compositor) lost de present/focus-stall op
  door via een native Wayland-surface te presenteren. Op X11/NVIDIA is de wrap niet nodig
  (daar de optie uitzetten).
- **`GAME_GAMESCOPE_RES=""`** (leeg/uit) → de **core auto-detected** de actieve monitormode
  via `xrandr` (op deze machine 1920x1080). Gamescope pakt daardoor nooit meer zelf een
  720p-mode. Pin optioneel met een expliciete `"WxH"`-export.
- **`dxvk.conf`** naast de game-exe:
  `dxvk.numCompilerThreads = 4` + `dxvk.enableGraphicsPipelineLibrary = True` → korte
  shader-compile-piek en snel aan het menu i.p.v. minutenlang ~195% CPU.
- **Prefix met warme DXVK-cache bewust behouden** i.p.v. verse provision.
- **`PROVISION_HOOKS=(install_gamescope)`** toegevoegd voor verse machines: skip als
  gamescope al aanwezig is; anders installatie via distro-pakketbeheerder (sudo/pkexec),
  met nette melding als dat niet kan (game draait dan zonder wrap). Hook-wijzigingen
  triggeren géén re-provision van de bestaande prefix (de marker vergelijkt alleen
  `SCRIPT_VERSION`).

## Boot/exit-bevestiging (gebruiker)

- Boot: zwart+spinner → blauwe logo → witte logo → hoofdmenu.
- Exit: verloopt netjes zolang je Proton de paar tellen teardown gunt
  (`Destroying swapchain` → `Primary child shut down` → alles weg). Te snel de taakbalk
  gebruiken = schijncrash.

## Wat níét nodig bleek

- **Vers prefix met koude DXVK-cache** — warme cache behouden.
- **Vaste gamescope-resolutie** — auto-detect via xrandr volstaat; pin alleen voor
  reproduceerbaarheid.
- **NVIDIA had geen gamescope-wrap nodig** (daar werkt het direct).

## Kanttekening

De launcher-comments spreken van `v3`/`v4`-substappen (regels 39-55), terwijl de
daadwerkelijke `SCRIPT_VERSION="2"` is. De eindstaat is v2; de comment-regels beschrijven
losse launch-time/test-wijzigingen die géén re-provision vereisten.

## Terugdraaien

- `GAME_GAMESCOPE="1"` weghalen/op 0 zetten → geen wrap (alleen op X11/NVIDIA aan te raden).
- `dxvk.conf` uit de gamemap verwijderen → compiler-gedrag terug naar default.
- Prefix opnieuw: `rm -rf ~/GAMEPREFIXES/CitiesSkylines`.
