# BEVINDINGEN — Witcher3RM

> Basis: het werkende script `/home/peter/GAME/run-witcher3.sh` en de daarin genoemde
> werkende prefix. Diagnose is hieruit afgeleid, niet uit eerdere sessies.

## Spel & werkende opzet

| | |
|---|---|
| Titel | The Witcher 3: Wild Hunt (GOTY) |
| AppID | `1495134320` (GOG) |
| Game | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TheWitcher3WildHuntGOTY` |
| EXE | `bin/x64_dx12/witcher3.exe` (64-bit) → `PREFIX_ARCH=win64` |
| Werkende prefix | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/protonprefix/witcher3-ge11` |
| Proton | `~/.steam/debian-installation/compatibilitytools.d/GE-Proton11-7/proton` |
| Runtime | `~/.steam/debian-installation/steamapps/common/SteamLinuxRuntime_4/_v2-entry-point` |
| Werkend script | `/home/peter/GAME/run-witcher3.sh` |

## Symptoom

Een **kale** `proton run <exe>` (of `wine64`): na `fsync: up and running.` volgt direct
`Failed loading SDL3 library.` en het proces sluit af — geen spelvenster.

## Oorzaak (hoge betrouwbaarheid)

De game wordt buiten de **Steam Linux Runtime 4**-container gestart. GE-Proton11-7
verklaart in zijn toolmanifest dat die runtime nodig is (`require_tool_appid 4183110`
= SteamLinuxRuntime_4). Steam start Proton daarom **nooit kaal**, maar altijd via:

```
<SLR4>/_v2-entry-point --verb=run -- <proton> run <exe>
```

De host (Debian) heeft **geen `libSDL3.so.0`** (bevestigd: `ldconfig -p | grep -i sdl3`
→ leeg). Alleen de steamrt4-container levert die bibliotheek. Zonder de wrapper faalt
het laden van SDL3 → de game sluit direct af.

## Bewijs (systeemstaat, deze sessie)

- Alle paden uit het script bestaan: game-map, `bin/x64_dx12/witcher3.exe`, de prefix,
  `GE-Proton11-7/proton` en `SteamLinuxRuntime_4/_v2-entry-point`.
- Host: **geen** SDL3 in `ldconfig -p` → de SDL3-load kan alleen binnen de runtime slagen.
- Prefix `protonprefix/witcher3-ge11` is eigendom van `peter:peter` (mode `2777`).
- Het script wijkt aantoonbaar af van een kale aanroep: het gaat via
  `_v2-entry-point --verb=run --`.
- Dubbele leading slash (`//mnt/...`) in de paden is onschadelijk (op Linux gelijk aan `/`).

## Werkende recipe (uit het script)

```bash
S="/home/peter/.steam/debian-installation"
PROTON="$S/compatibilitytools.d/GE-Proton11-7/proton"
RUNTIME="$S/steamapps/common/SteamLinuxRuntime_4/_v2-entry-point"
GAMEDIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TheWitcher3WildHuntGOTY"
EXE="$GAMEDIR/bin/x64_dx12/witcher3.exe"

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$S"
export STEAM_COMPAT_DATA_PATH="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/protonprefix/witcher3-ge11"
export SteamAppId=1495134320
export SteamGameId=1495134320

unset WINEPREFIX WINEESYNC WINEFSYNC 2>/dev/null || true

cd "$GAMEDIR/bin/x64_dx12"
exec "$RUNTIME" --verb=run -- "$PROTON" run "$EXE" "$@"
```

Kernpunten:
- `RUNTIME` = de SLR4-`_v2-entry-point`; dit is de fix.
- `STEAM_COMPAT_DATA_PATH` laat Proton de prefix zelf afleiden (daarom `WINEPREFIX` unset).
- `cd bin/x64_dx12`: de werkmap die de game verwacht.
- Let op: het bewezen script gebruikt de subcommand **`run`**, niet `waitforexitandrun`.

## Actieplan voor de launcher

1. **Per-game launcher** `template-scripts/game-launchers/LINUXLAUNCHERS/witcher3rm.sh`
   (dun), volgens het patroon van de andere launchers:
   - `GAME_NAME="Witcher3RM"`, `GAME_DIR=<NFS game-map>`,
     `GAME_EXE="$GAME_DIR/bin/x64_dx12/witcher3.exe"`, `PREFIX_ARCH="win64"`
   - `PROTON_ENABLED=1`, `PROTON_PIN="GE-Proton11-7"`, `STEAM_APPID="1495134320"`
   - runtime-wrapper **aan** (zie punt 2)
   - `GAME_DISPLAY_NAME`, `GAME_ICON="Witcher3RM.png"`, `CREATE_DESKTOP_SHORTCUT="1"`
   - `source ".../../../game-core/game-common.sh"; game_main "$@"`

2. **Core-uitbreiding (noodzakelijk).** `game_launch` in `game-core/game-common.sh`
   roept de runner nu **direct** aan (regel ~928):
   ```bash
   "${gscope[@]}" "$runner" waitforexitandrun "$GAME_EXE" "$@"
   ```
   Er is **geen** `_v2-entry-point`-wrapper. Witcher3 — en elke game met dezelfde
   `require_tool_appid` — faalt daardoor óók via het framework met `Failed loading SDL3`.
   Voeg een runtime-wrapper toe; als een vlag (bv. `GAME_STEAM_RUNTIME=1`) staat:
   ```bash
   exec "$SLR_ENTRY" --verb=run -- "$runner" waitforexitandrun "$GAME_EXE" "$@"
   ```
   Detecteer `$SLR_ENTRY` generiek (zoek `steamapps/common/SteamLinuxRuntime_4/_v2-entry-point`,
   en eventueel `..._sniper`) **binnen de Steam-library van de gebruiker** — niet hard
   gecodeerd op `/home/peter/...`. Verifieer welke subcommand binnen de wrapper werkt
   en houd de bewezen variant (`run`) aan.

3. **Prefix lokaal per gebruiker.** De bewezen prefix staat nu op de NFS-share
   (`protonprefix/witcher3-ge11`). Voor de launcher: `STEAM_COMPAT_DATA_PATH="$HOME/GAMEPREFIXES/Witcher3RM"`
   zodat elke gebruiker eigenaar van zijn eigen prefix is. De NFS-prefix blijft de
   bewezen referentie om tegen te verifiëren.

4. **Desktop + icoon.** Core regelt dit via `CREATE_DESKTOP_SHORTCUT` en `GAME_ICON`;
   het icoon `Witcher3RM.png` staat al in `game-launchers/gameicons/`.

## Gebruiker zonder (de juiste) Proton

- **Verwacht:** `PROTON_PIN="GE-Proton11-7"`. Ontbreekt die, dan valt `_detect_proton`
  terug: `PROTON_RUNNER` → `PROTON_PIN` → hoogste `GE-Proton*` → Steam-Proton →
  `umu-run`. Vindt hij niets, dan waarschuwt `_warn_missing_proton` met een verwijzing
  naar `tools/install-proton.sh`.
- **De runtime is de tweede afhankelijkheid.** Ook met een andere GE-Proton (zelfde
  `require_tool_appid`) is de SLR4-wrapper nodig. Daarom:
  - Steam-installatie met `SteamLinuxRuntime_4` aanwezig → gebruik die `_v2-entry-point`.
  - Alleen `umu-run` aanwezig → laat umu de runtime **zelf** regelen (dan géén losse
    `_v2-entry-point`).
  - Proton aanwezig maar géén runtime → **duidelijke melding** + verwijzing naar
    `install-proton.sh`/Steam. **Niet** stil terugvallen op een kale `proton run` —
    dat geeft juist de SDL3-exit.
- Pin de runtime-entry niet op één vast pad; leid hem af uit `$HOME`/de gevonden library,
  net als `_detect_proton` met de Proton-runners doet.

## Terugdraaien

- Launcher weg: `rm .../LINUXLAUNCHERS/witcher3rm.sh` (raakt prefix en game niet).
- Prefix opnieuw: `rm -rf ~/GAMEPREFIXES/Witcher3RM` (game-bestanden blijven staan).

## Zie ook

- `WERKWIJZE.md` — algemene werkmethode.
- `game-core/game-common.sh` — `_detect_proton`, `_warn_missing_proton`, `game_launch`.
- `game-launchers/LINUXLAUNCHERS/ori-willofthewisps.sh` — launcher-patroon.
- `tools/install-proton.sh` — Proton-installatie voor de gebruiker.
