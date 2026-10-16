# BEVINDINGEN — Submerged (2015)

Datum: 2026-10-15. Status: **analyse afgerond; actieplan klaar (nog niet geverifieerd op de
productie-prefix).** Rol: Diagnostiek-Agent (read-only; géén launchers geschreven).
Bron: `WERKWIJZE.md`, de werkende referentie `movedprefixes/Submerged`, en de testruns in
deze sessie.

## Conclusie

- De game is **speelbaar in wine-modus op een win64-prefix**. Er is **geen DXVK** nodig en
  **geen speciale provisioning**: een verse `wineboot -i` win64-prefix start de game ook
  (window "Submerged" verscheen).
- Er bestaat **nog geen launcher** (`LINUXLAUNCHERS/submerged.sh`) en **geen prefix in
  `~/GAMEPREFIXES/`**.
- Referentie is **steigersbouw** (`movedprefixes/Submerged`, NFS): een **meetlat, geen
  sjabloon**. Verdwijnt binnenkort → nu vastleggen.

## Game-analyse

- `Submerged.exe` (root, 459 KB, 2015-08-04) = **bootstrapper** → de echte game is
  `Submerged/Binaries/Win64/Submerged-Win64-Shipping.exe` (35 MB). **x86-64** → win64-prefix.
- UE4 (2015). Renderer: **D3D11 via wined3d** (wine-builtin `d3d11`/`dxgi`), **geen DXVK**.
  Statische imports o.a. `MSVCP120`/`MSVCR120` (VS2013), `d3d11`/`d3d9`, `dsound`,
  `x3daudio1_7`, `xapofx1_5`, `xinput1_3`, `OPENGL32`.
- Installatie: Inno Setup; `_CommonRedist` bevat DirectX Jun2010, vcredist 2012 + 2013,
  .NET 4.5.1.
- De game schrijft **zelf** haar sleutels/map: `HKCU\Software\Epic Games\Unreal Engine\
  {Hardware Survey,Identifiers}` en `Submerged/Saved/` (Config, `HardwareSurvey/dxdiag.txt`,
  `SaveGames/*.sav`).

## Bewijs: werkende referentie

Werkend commando:

```
WINEPREFIX=/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/movedprefixes/Submerged \
  wine64 /mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Submerged/Submerged.exe
```

- `wine64` = `/usr/bin/wine64` = **wine-10.0 (debian)**.
- Bewijs dat de game hierin draaide: UE Hardware Survey/Identifiers in `user.reg`
  (timestamps 1792111317 / 1792111343), `Saved/HardwareSurvey/dxdiag.txt` en
  `SaveGames/SubProfile.sav` + `SUB_SG_0.sav`.
- Register: alleen de Inno Setup uninstall-sleutel met
  `InstallLocation=Z:\mnt\...\WINDOWSGAMES\Submerged\` (ontkoppel-vermelding).
  **Geen** custom `DllOverrides`, **geen** `winetricks.log`.
- VC-runtimes in `drive_c/windows/system32`: `msvcp110`/`msvcr110` native (2012),
  `msvcp120` native (2013, 660128 B); `msvcr120` = **wine-builtin** (3889987 B).

## Getest in deze sessie

| test | resultaat |
|---|---|
| Referentie-prefix + `wine64` (10.0) | window "Submerged" verschijnt; **game werkt** (gebruiker bevestigt) |
| **Verse** `wineboot -i` win64-prefix (zónder redists) + `wine64` | window "Submerged" verschijnt → redists **niet** vereist |
| Verse win64-prefix + `wine` (11.0) | window "Submerged" verschijnt → wine-versie **niet** bepalend |
| Referentie-register op DllOverrides/winetricks | afwezig → geen override-bug |

## Wat NIET de oorzaak bleek

- **Ontbrekende redists** (het verschil referentie ↔ vers): een verse prefix start óók → onschuldig.
- **DXVK**: niet gebruikt; wined3d volstaat.
- **Wine-versie**: zowel 10.0 als 11.0 starten de game.
- **DllOverrides / register-hook met installatiepaden**: niet aanwezig en niet nodig; de game
  maakt haar eigen UE-sleutels zelf aan (definitief te bevestigen in de eindverificatie).

## Restrisico / te verifiëren vóór `movedprefixes/` verdwijnt

- Er is **geen crashende productie-prefix** gevonden; de oorspronkelijke klacht is in deze
  sessie **niet gereproduceerd**. De conclusie "een schone win64-prefix volstaat" moet daarom
  op de **productie-prefix `~/GAMEPREFIXES/Submerged`** worden geverifieerd.
- `template-scripts/game-core/game-common.sh` (regel 1118) start wine-modus met
  `${WINE_CMD:-wine}` = **wine-11.0**, terwijl de werkende referentie **wine-10.0** gebruikte.
  Beide werken in de test; pin `WINE_CMD` alleen als de eindverificatie anders uitwijst.
- Spelbestanden staan op de **NFS-share** (`/mnt/VG_00/...`, owner `nfs`). Draaien vanaf NFS
  werkt maar is traag; overweeg een lokale kopie.

## Actieplan voor de Launcher-Builder

1. Dun launcher-script `template-scripts/game-launchers/LINUXLAUNCHERS/submerged.sh` volgens de
   boilerplate; **geen** `PROVISION_HOOKS`, **geen** `PRE_LAUNCH_HOOKS`.
2. Verse prefix `~/GAMEPREFIXES/Submerged` (win64) via `game-common.sh`; **verifieer tegen de
   referentie** zolang `movedprefixes/Submerged` nog bestaat.
3. `WINE_CMD` default laten (wine 11.0 werkt) — niet pinnen tenzij verificatie anders uitwijst.
4. **Icoon**: niet aanwezig in de gamemap → extern aanleveren (512×512 PNG, transparant) als
   `template-scripts/game-launchers/gameicons/Submerged.png`.
5. `.desktop`-test uitvoeren (shortcut verschijnt + spel start).

Boilerplate-velden:

```bash
export GAME_NAME="Submerged"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Submerged"
export GAME_EXE="$GAME_DIR/Submerged.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
```

## Overdracht

Analyse afgerond → **doorverwijzen naar de Launcher-Builder Agent** voor uitvoering van het
actieplan. Dit document is de enige output van de Diagnostiek-Agent.
