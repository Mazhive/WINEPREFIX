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

---

## 5. Versie / changelog

De fork heeft een eigen versie (`APP_VERSION`). Bij een wijziging:
versie ophogen (patch), een kopie in `gui-version/` plaatsen
(`game-gui-forkV<versie>.py`) en `gui-version/changelog.md` bijwerken.

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
