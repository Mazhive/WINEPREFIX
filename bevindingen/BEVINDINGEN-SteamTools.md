# BEVINDINGEN — Steam-tools (non-Steam-fusie)

Werkmethode: `WERKWIJZE.md`. Alle tools in `template-scripts/tools/`.
Ontstaan bij de non-Steam-fusie-route (games die als non-Steam game aan Steam worden
toegevoegd). Géén launcher-onderdeel; losse hulpmiddelen.

## Toolset

| Tool | Doet |
|---|---|
| `steam-nonsteam-fix.sh` | `inspect \| neutralise \| restore \| fake \| scan \| boom` (`--dry-run`, `--appid`, `--len`) — omgaan met `steam_appid.txt`/Steam-fusie-conflicten |
| `appid.fromname.sh` | naam → appid (Digital-root-condensering; standaard 8 cijfers; `-l <len>` voor bv. BF's `261570`-formaat) |
| `appid.numerator.py` | de voorwaartse appid-nummering |
| `appid.numerator.reverse.py` | reverse-lookup van die methode |
| `steam-shortcut-cleanup.sh` | `list \| verify \| remove <naam>` (`--commit`/`--force`/`--file`) — `shortcuts.vdf` bewerken |

## `steam-nonsteam-fix.sh`

- **Eerste echte toepassing:** WOTW's `steam_appid.txt` (1057090) op 2026-09-20
  **geneutraliseerd**.
- **Scan (2026-09, WINDOWSGAMES):** conflict-dragers gevonden: **Eve Online (8500)** en
  **AOW.Planetfall (718850 + `steam_api64.dll`)**.

## `appid.fromname.sh` + `appid.numerator.reverse.py`

- Naam → appid via Digital-root-condensering (standaard 8 cijfers).
- `-l <len>` voor afwijkende lengtes (bv. BF `261570`).
- 10/10 cross-check tegen `appid.numerator.py` (incl. reverse).

## `steam-shortcut-cleanup.sh`

- **Kernprobleem:** `shortcuts.vdf` is **binair VDF**.
- De bewezen `vdf`-pythonlib doet load/roundtrip — geverifieerd **byte-exact 10499 B** — en
  reikt writes uit.
- `remove` **weigert meer dan één match** en schrijft **standaard NIET** (dry-run).
  `--commit` vereist: **+ Steam gesloten + backup**.
- **Echt bestand** (userdata `203236556`): 21 entries.
  - **Forza Horizon 5 (#20)** staat er nog in en is klaar voor één-opdracht-verwijdering
    zodra Steam gesloten is.
  - Test-verwijdering slaagde op een **kopie** (20 entries, stabiel).

## Terugdraaien

- `steam_appid.txt`-neutralisatie terugdraaien met `steam-nonsteam-fix.sh restore`.
- `shortcuts.vdf`: herstel uit backup (door `--commit` weggeschreven).
