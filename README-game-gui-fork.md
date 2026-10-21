# Game Launcher Fork (`game-gui-fork.py`)

Een **fork** van `game-gui.py` die dezelfde launcher-infrastructuur
(`template-scripts/game-launchers`, `game-core`, `gameicons`) deelt, maar
daarnaast **emulatie** toevoegt via een drill-down navigatie.

De hoofd-GUI `game-gui.py` blijft hierbij **ongemoeid**; beide GUI's kunnen
los van elkaar doorontwikkeld worden.

---

## 1. Navigatiemodel (drill-down)

Net als een bestandsverkenner, met een scroller per niveau en een
terug-kaart als eerste item:

```
HOOFD-SCROLLER (platform)
[ Windows ] [ Linux ] [ Sony ] [ Nintendo ] [ Xbox ] [ Commodore ] ...
        │ klik "Sony"
        ▼
SYSTEEM-SCROLLER (versies)
[ PS1 ] [ PS2 ] [ PS3 ] [ PSP ]
        │ klik "PS2"
        ▼
[letter-buckets]  (alleen als een lijst groot is, > 500 items)
        │ klik "a-m"
        ▼
GAME-SCROLLER  ← klik op een game-icoon = emulator start direct met de rom
        ◀ Terug  →  systeem  →  platform  →  hoofd
```

- **Windows/Linux-games** starten exact zoals in `game-gui.py` via
  `LINUXLAUNCHERS/<game>.sh`.
- **Emu-games** starten `EMU-LAUNCHERS/emu-launch.sh` met de juiste
  systeem-sleutel en rom.
- De boom wordt **dynamisch opgebouwd** uit wat er werkelijk staat in
  `/mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/` (de mappen `WINDOWS` en `LINUX`
  worden overgeslagen — die horen bij de PC-launchers).

---

## 2. Configuratie: `emulation.conf`

De koppeling systeem → emulator staat **per PC in de home-map**:

```
~/.config/gamelauncher/emulation.conf
```

De repo-versie `EMU-LAUNCHERS/emulation.conf` is het **sjabloon/fallback**
(gebruikt als de home-versie ontbreekt). Zowel `game-gui-fork.py` als
`emu-launch.sh` lezen de home-versie eerst. De GUI geeft het gekozen pad
door via de env-var `GAME_EMU_CONF`.

### Formaat

```ini
[systeem-sleutel]
title=Weergavenaam
emu=/volledig/pad/naar/emulator        # leeg = nog niet gekoppeld
args=%ROM%                             # %ROM% wordt vervangen door het game-pad
status=ok                              # ok | missing
accept_dir=1                           # optioneel: emulator accepteert een MAP (bv. RPCS3)
```

| veld | betekenis |
|---|---|
| `title` | naam in de scroller |
| `emu` | volledig pad naar de emulator (AppImage/binair) |
| `args` | argumenten; `%ROM%` = het rom-pad (iso/cue/map) |
| `status` | `ok` of `missing` |
| `accept_dir` | `1` als de emulator een **map** als argument accepteert |

### Emulators

Emulators staan **portable** op de schijf, onder:

```
/mnt/VG_00/Portable.APPS/EMU/<VENDOR>/<CONSOLE>/
```

### Systeem-sleutels

PlayStation: `psx`, `ps2`, `ps3`, `psp` — Xbox: `xbox` — Commodore: `c64`,
`c128`, `vic20`, `amiga` — Nintendo: `nes`, `famicom`, `snes`, `n64`, `gb`,
`gbc`, `gba`, `nds`, `3ds`, `wii` — Sega: `megadrive`, `mastersystem`,
`gamegear` — Atari: `atari2600`, `atari7800`, `atarilynx` — overig:
`turbogrfx`, `neogeo`, `mame`, `mamemame4all`, `amstradcpc`, `msx`, `arcade`.

De systeem-mapnaam in `GAMES/GAMES/` wordt automatisch op deze sleutel
gemapt (met een paar aliassen, zie `_SYSTEM_ALIASES` in de bron).

---

## 3. Emulator-detectie (`emulators.json`)

Bij het opstarten controleert de fork alle systemen uit `emulation.conf` en
schrijft het resultaat naar:

```
~/.config/gamelauncher/emulators.json
```

Als kandidaten worden **zowel** het pad uit de home-conf **als** uit de
repo-conf meegenomen (bekende alternatieven, bv. `/usr/bin/x64sc`).

Voorbeeld:

```json
{
  "generated": 1792377109,
  "systems": {
    "psx": {
      "title": "PlayStation (PS1)",
      "emu": "/mnt/VG_00/Portable.APPS/EMU/SONY/PSX/DuckStation-x64.AppImage",
      "present": true,
      "candidates": ["...DuckStation-x64.AppImage"]
    }
  }
}
```

Als een systeem geen (gevonden) emulator heeft, toont de GUI bij het
betreden van dat systeem een melding in de terminal met de ontbrekende
sleutel en het conf-pad.

---

## 4. Startflow van een emu-game

```
Klik op game-icoon  (bv. Sony › PSP › Final Fantasy II)
   │  EmuGame bevat: rom-pad + systeem-sleutel
   ▼
game-gui-fork.py  →  env: GAME_SYSTEM, GAME_ROM, GAME_DISPLAY_NAME,
                          GAME_GUI=1, GAME_EMU_CONF
   ▼
EMU-LAUNCHERS/emu-launch.sh
   │  leest de betreffende sectie uit emulation.conf
   │  bouwt het commando (args met %ROM%) en start de emulator
   ▼
Emulator start direct met de rom  →  spelen
```

`EMU-LAUNCHERS/<vendor>/<systeem>.sh` zijn dunne wrappers die alleen
`GAME_SYSTEM` zetten en doorverwijzen naar `emu-launch.sh`.

### Mappen en iso's

Sommige games staan als **map** in de bibliotheek (bv. PS2: een map met
daarin één `.iso`, of een uitgepakte folder-dump met `SYSTEM.CNF`). Is de
emulator geen map-emulator (`accept_dir` ≠ `1`), dan lost `emu-launch.sh`
dit op vóór het starten:

1. **Rom in de map?** Bevat de map een schijfimage/rom-bestand
   (`iso` › `chd` › `cso` › `rvz` › `wbfs` › `gcm` › `bin`/`cue` …), dan
   wordt dat bestand gebruikt. Een echte folder-dump (met `SYSTEM.CNF`)
   wordt hier niet als container gezien.
2. **Anders packen.** Was er geen rom-bestand, dan wordt de map met
   `xdvdfs pack <map> <iso>` naar een **gecachte iso** gepackt:

   ```
   ~/.cache/gamelauncher/iso/<map>_<hash>.iso
   ```

   De cache wordt hergebruikt zolang de iso nieuwer is dan de map. Vereist
   `xdvdfs` in `PATH`; ontbreekt dat, dan meldt de launcher dit en stopt.

Paden met spaties en haakjes blijven intact (geen `eval`).

---

## 5. Versie / changelog

De fork heeft een eigen versie (`APP_VERSION`). Bij een wijziging:
versie ophogen (patch), een kopie in `gui-version/` plaatsen
(`game-gui-forkV<versie>.py`) en `gui-version/changelog.md` bijwerken.

**Huidige versie:** `0.2.6` (2026-10-20) — zie §10 voor wijzigingen.

---

## 6. Emulator installeren

Ontbreekt een emulator bij het starten van een emu-game, dan biedt de fork
aan om die te installeren:

```
Klik op game-icoon (emu-game)
   │  status=missing / emu-pad bestaat niet
   ▼
QMessageBox: "<title> is nog niet geconfigureerd … Nu installeren? (emu-install.sh)"
   │  "Ja"
   ▼
EMU-LAUNCHERS/emu-install.sh   (env: GAME_SYSTEM, GAME_EMU_CONF)
   │  sourcet game-core/game-common.sh → _run_hook install_emu
   ▼
game-core/hooks/install_emu.sh
   │  detect → ask-yesno.sh → downloaden → uitpakken → chmod +x → conf bijwerken
   │  (url= of gh_repo= uit de sectie; optioneel core_url= voor libretro)
   ▼
conf bijgewerkt (emu=…, status=ok)  →  GUI herdetecteert  →  start opnieuw
```

Dezelfde install-trigger zit ook in `emu-launch.sh`: bij een ontbrekende
emulator probeert die `emu-install.sh` en herleest daarna de conf.

Emulators worden dus bij voorkeur via de launcher geïnstalleerd; handmatig
koppelen in `emulation.conf` blijft mogelijk als fallback.

---

## 7. Standaard-config (preconf) — "geen menu-gerommel"

Elke emulator kan een **preconf**-map naast de AppImage/binary hebben met
daarin een kant-en-klare configuratie. Bij het starten zet `emu-launch.sh`
die automatisch in de user-config van de emulator, zodat een gebruiker de
game direct kan starten zonder eerst menu's door te lopen.

```
<mapper-van-de-emulator>/preconf/      ← std-config (in de appimage-map)
/                  ├── bios/…          ← bv. PS2-BIOS
/                  └── inis/…          ← bv. PCSX2.ini
```

Toepassing bij het starten:

- **Locatie:** `<map van emu>/preconf/`, of expliciet via `preconf=` in de conf.
- **Doelmap:** het `userconf=`-veld uit de sectie (bv. `~/.config/PCSX2`);
  `~` wordt uitgebreid naar de home-map.
- **Samenvoegen:** `cp -rn` — ontbrekende bestanden worden gekopieerd,
  **bestaande bestanden van de gebruiker worden nooit overschreven**.

Twee conf-velden per systeem:

| veld | betekenis |
|---|---|
| `userconf` | config-/datamap van de emulator (doel), bv. `~/.config/PCSX2` |
| `preconf` | optioneel; pad naar de std-config (default `<emu-dir>/preconf`) |

Voorbeeld `[ps2]`:

```ini
[ps2]
title=PlayStation 2 (PS2)
emu=/mnt/VG_00/Portable.APPS/EMU/SONY/PS2/pcsx2-v2.8.2-x64-Qt.AppImage
args=-nogui -fullscreen -fastboot %ROM%
status=ok
userconf=~/.config/PCSX2
```

Met `~/.config/PCSX2/bios/` gevuld (uit de preconf) en de boot-flags in
`args` start PCSX2 direct in de game, in fullscreen, zonder GUI.

---

## 8. Iconen-boomstructuur

De fork gebruikt een centrale icon-map (`ICONS_ROOT`, standaard
`/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/`) die de gebruiker kan
overschrijven via `settings.conf` (`ICONS_ROOT=/pad/naar/icons`). Bij elke
opstart (en bij wijzigen van het pad) worden ontbrekende submappen **automatisch
aangemaakt**.

### Boomstructuur

```
GAMEICONS/                    ← ICONS_ROOT
├── systems/                  ← systeem-iconen (snes.png, ps2.png, …)
│   ├── snes.png
│   ├── ps2.png
│   └── …
├── emu-gameicons/            ← platte fallback (optioneel)
│   └── <display_name>.png
├── EMU-ICONS/                ← geneste boom (spiegelt GAMES/GAMES/)
│   ├── NINTENDO/
│   │   ├── SNES/
│   │   │   └── Nintendo SNES.png
│   │   ├── NES/
│   │   │   └── Nintendo NES.png
│   │   └── …
│   ├── PLAYSTATION/
│   │   ├── PS2/
│   │   │   ├── Fantastic 4 PS2 PAL.png
│   │   │   └── …
│   │   ├── PS3/
│   │   │   ├── BCES01584 The Last Of Us.png
│   │   │   └── …
│   │   └── …
│   ├── XBOX/
│   │   ├── Amped/
│   │   │   └── Xbox Amped.png
│   │   └── …
│   └── _index.json           ← scrape-index (bron van waarheid)
├── LINUXLAUNCHERS/           ← PC-launcher scripts
├── EMU-LAUNCHERS/            ← emulator launchers + emulation.conf
└── back.jpg                  ← achtergrond voor Terug-kaart
```

### Match-logica

| Entiteit | Zoekvolgorde |
|---|---|
| **NavNode** (systeem, bv. "Nintendo › SNES") | 1. `systems/snes.png` 2. `EMU-ICONS/_index.json` → `by_system["snes"]` 3. `gameicons/` root |
| **EmuGame** (game, bv. "Xbox › Amped") | 1. `EMU-ICONS/_index.json` → `by_path["/mnt/.../GAMES/GAMES/XBOX/Amped"]` 2. `by_system["xbox"]` 3. `emu-gameicons/<display_name>.png` 4. placeholder |

- **Game-icoon**: exacte match op absolute `rom_path` via `_index.json` → werkt ook als bestandsnaam ≠ mapnaam.
- **Systeem-icoon**: match op `system_key` (`snes`, `ps2`, …) via `_index.json` of `systems/`.
- **Fallback**: platte `emu-gameicons/` op genormaliseerde `display_name` (bestaande logica).

### `_index.json` (in `EMU-ICONS/`)

Deze JSON is de **bron van waarheid** voor emu-icons. Het wordt gegenereerd door
`scrape_icons/` (fase 3: `place`) en bevat voor elke game/systeem:

```json
{
  "NINTENDO/SNES": {
    "platform": "NINTENDO",
    "system": "snes",
    "system_folder": "SNES",
    "folder_name": "SNES",
    "display_name": "Nintendo SNES",
    "icon_rel_path": "NINTENDO/SNES/Nintendo SNES.png",
    "icon_abs_path": "/mnt/.../GAMEICONS/EMU-ICONS/NINTENDO/SNES/Nintendo SNES.png",
    "search_terms": ["Super Nintendo", "Super Nintendo snes", "SNES snes", "SNES"],
    "source": "bing",
    "matched_name": "Super Nintendo",
    "scraped_at": "2026-10-19T22:44:02.265157Z",
    "status": "placed",
    "placed_at": "2026-10-19T22:45:41.645972Z"
  },
  "XBOX/Amped": { … }
}
```

De fork leest dit bestand **relatief aan de icon-root** — geen afhankelijkheid
van `scrape_icons/`. Zolang `EMU-ICONS/_index.json` aanwezig is, werkt de
icon-opzoeking.

### Icon pack (toekomst)

Een **icon pack** = de gehele `EMU-ICONS/` map (inclusief `_index.json`).
Dit is een zelfstandig, distribueerbaar pakket. `scrape_icons/` is alleen
nodig voor het *genereren* van de icons, niet voor het *gebruiken*.

### Instellen van de icon-map

1. Open de GUI → Opties → **Icon-map** veld.
2. Kies de hoofdmap die `systems/`, `EMU-ICONS/`, `EMU-LAUNCHERS/` bevat.
3. Druk **Valideren** of herstart de GUI — ontbrekende mappen worden aangemaakt.
4. Zet je eigen icons in `systems/` (systeem) of `emu-gameicons/` (platte fallback).
5. Voor volledige emu-iconen: draai `scrape_icons/` of plaats een icon pack in `EMU-ICONS/`.

---

## 9. Richtlijnen & ontwerpprincipes

Deze fork volgt een aantal vaste principes om robuust, onderhoudbaar en
gebruiksvriendelijk te blijven.

### 9.1 Geen harde afhankelijkheden van externe tools
- `scrape_icons/` is **alleen voor generatie**. De fork leest `EMU-ICONS/_index.json`
  relatief aan de icon-root — geen import van `scrape_icons/` modules.
- Een **icon pack** (`EMU-ICONS/` + `_index.json`) is zelfstandig distribueerbaar.

### 9.2 Automatische structuur, handmatige controle
- `ensure_icon_structure()` maakt ontbrekende mappen aan bij **elke opstart**.
- `validate_icon_structure()` controleert de boom en waarschuwt (niet blokkeert).
- Gebruiker blijft eigenaar: eigen icons in `systems/` of `emu-gameicons/` hebben
  altijd voorrang op scrape-index.

### 9.3 Exacte match > fuzzy match
- Game-iconen: match op **absolute `rom_path`** via `_index.json` (100% betrouwbaar).
- Systeem-iconen: match op `system_key` (`snes`, `ps2`, …).
- Fuzzy match (substring) **alleen** als fallback in `emu-gameicons/` — nooit primair.

### 9.4 Twee icon-bronnen, één zoekvolgorde
| Bron | Doel | Prioriteit |
|---|---|---|
| `EMU-ICONS/_index.json` | Scrape-resultaten, icon packs | 1 (game), 2 (systeem) |
| `systems/` | Handmatige systeem-iconen | 1 (systeem) |
| `emu-gameicons/` | Platte fallback (legacy) | 3 (game), 3 (systeem) |
| Placeholder | Laatste redmiddel | 4 |

### 9.5 Versiebeheer & traceerbaarheid
- Elke wijziging: `APP_VERSION` patch (+0.0.1), kopie in `gui-version/`,
  `changelog.md` entry.
- `scrape_icons/` heeft eigen versie/log (`scrape_log.json`, `games_index.json`).

### 9.6 Foutafhandeling = degradatie, geen crash
- Ontbrekend `_index.json` → fallback naar boom-scan (geen crash).
- Ontbrekende icon → placeholder (geen lege kaart).
- Ongeldige `ICONS_ROOT` → fallback naar default (geen crash).

---

## 10. Wijzigingen v0.2.6 (2026-10-20)

| Wijziging | Beschrijving |
|---|---|
| **Iconen-boom gekoppeld** | `EMU-ICONS/` (geneste boom) + `_index.json` is nu bron van waarheid voor emu-icons. |
| **Auto-aanmaak structuur** | `ensure_icon_structure()` maakt `systems/`, `emu-gameicons/`, `EMU-ICONS/`, `LINUXLAUNCHERS/`, `EMU-LAUNCHERS/` aan bij elke opstart. |
| **Index-based resolve** | `_scrape_icon_index()` laadt `_index.json` → `by_path` (rom_path→icon) + `by_system` (system_key→icon). |
| **EmuGame resolve** | 1) `by_path[rom_path]` 2) `by_system[system]` 3) `emu-gameicons/` fallback. |
| **NavNode resolve** | Gebruikt ook `by_system` uit scrape-index voor systeem-navnodes. |
| **Validate uitgebreid** | Controleert nu ook `EMU-ICONS/_index.json`. |
| **Scrape placer** | Schrijft index nu ook naar `EMU-ICONS/_index.json` (naast `scrape_icons/`). |
| **Documentatie** | §8 Iconen-boomstructuur, §9 Richtlijnen, §10 Wijzigingen toegevoegd. |
| **Versie** | `0.2.5` → `0.2.6` (kopie `game-gui-forkV0.2.6.py`, changelog bijgewerkt). |
