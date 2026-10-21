# Sony EMU-LAUNCHERS — PlayStation Emulator Afhandeling

## Overzicht

Dit systeem biedt **generieke launchers** voor alle Sony PlayStation emulators.
In plaats van duizenden losse game-launchers is er **één launcher per systeem**
(psx.sh, ps2.sh, ps3.sh) die alle games van dat systeem afhandelt.

## Structuur

```
EMU-LAUNCHERS/
├── emu-launch.sh          # Generieke launcher (leest emulation.conf)
├── emu-install.sh         # Installeert emulators (status=missing → ok)
├── emulation.conf         # Config: systeem → emulator + args
├── sony-EMU-README.md     # Dit bestand (Sony-specifiek)
├── preconf/               # Standaard-config (gekopieerd naar userconf)
│   ├── duckstation/       # PS1 DuckStation preconf
│   │   ├── settings.ini   # Instellingen + game library pad
│   │   └── bios/          # PS1 BIOS bestanden
│   └── pcsx2/             # PS2 PCSX2 preconf
│       ├── PCSX2.ini      # Instellingen + game library pad
│       └── bios/          # PS2 BIOS bestanden
└── sony/
    ├── psx.sh             # Wrapper → emu-launch.sh (GAME_SYSTEM=psx)
    ├── ps2.sh             # Wrapper → emu-launch.sh (GAME_SYSTEM=ps2)
    └── ps3.sh             # Wrapper → emu-launch.sh (GAME_SYSTEM=ps3)
```

## Hoe het werkt

### 1. Configuratie (emulation.conf)

Elke systeem-sleutel heeft een sectie in `emulation.conf`:

```ini
[psx]
title=PlayStation (PS1)
emu=/mnt/VG_00/PUBLIC-LIBRARY/EMU/SONY/PSX/DuckStation-x64.appimage
args=%ROM%
status=ok
userconf=~/.local/share/duckstation

[ps2]
title=PlayStation 2 (PS2)
emu=/mnt/VG_00/Portable.APPS/EMU/SONY/PS2/pcsx2-v2.8.2-x64-Qt.AppImage
args=-nogui -fullscreen -fastboot %ROM%
status=ok
userconf=~/.config/PCSX2

[ps3]
title=PlayStation 3 (PS3)
emu=/mnt/VG_00/PUBLIC-LIBRARY/EMU/SONY/PSX3/rpcs3-v0.0.22-13538-c14e79f8_linux64.AppImage
args=--no-gui %ROM%
status=ok
accept_dir=1
```

**Velden:**
- `title` = weergave-naam in GUI
- `emu` = pad naar emulator-binary (AppImage)
- `args` = argumenten; `%ROM%` wordt vervangen door het rom-pad
- `status` = `ok` | `missing` (wordt automatisch gecontroleerd)
- `accept_dir` = `1` als emulator een MAP accepteert (PS3/RPCS3)
- `userconf` = pad naar user-config map (voor preconf kopiëren)

### 2. Launch flow

```
GUI klik op game
    ↓
export GAME_SYSTEM=psx
export GAME_ROM=/pad/naar/game.iso
export GAME_EMU_CONF=/pad/naar/emulation.conf
    ↓
emu-launch.sh
    ├─ Leest emulation.conf [psx]
    ├─ Controleert of emu bestaat (anders: emu-install.sh)
    ├─ Kopieert preconf → userconf (als die bestaat)
    ├─ Vervangt %ROM% door GAME_ROM
    └─ exec "$emu" args...
```

### 3. Game-scanning (GUI)

De GUI scant automatisch game-mappen en maakt `EmuGame` objecten:
- Games worden gevonden op bestandsnaam (.iso, .cue, .chd, .mds, etc.)
- **Geen library-database nodig** - de mapstructuur IS de database
- Ondersteunt bucket-structuur (a-m, n-z) of platte structuur

## Preconf (standaard-config voor nieuwe gebruikers)

### Doel

Nieuwe gebruikers hoeven **geen handmatige configuratie** te doen:
- Game library wordt automatisch gescand
- BIOS-bestanden staan er al in
- Settings zijn voorgeconfigureerd
- **Geen games toevoegen tijdens eerste opstart!**

### Hoe het werkt

1. Gebruiker start game voor het eerst
2. `emu-launch.sh` controleert of `preconf/` map bestaat
3. Als `userconf=` ingesteld is → preconf gekopieerd (nooit overschrijven!)
4. Emulator start met standaard-config + ingevulde library

### Belangrijk

- Preconf wordt **nooit overschreven** als bestand al bestaat (gebruiker wint)
- Alleen gekopieerd bij **eerste start** of als bestand ontbreekt
- Test met: `cp -rn preconf/duckstation/. ~/.local/share/duckstation/`

---

## PS1 DuckStation Configuratie

### Status: ✅ Geconfigureerd (19 okt 2026)

**Emulator:**
```
/mnt/VG_00/PUBLIC-LIBRARY/EMU/SONY/PSX/DuckStation-x64.appimage
```

**Config:**
```ini
[psx]
title=PlayStation (PS1)
emu=/mnt/VG_00/PUBLIC-LIBRARY/EMU/SONY/PSX/DuckStation-x64.appimage
args=%ROM%
status=ok
userconf=~/.local/share/duckstation
```

**Config-bestandslocatie:**
```
~/.local/share/duckstation/
├── settings.ini           # Hoofdinstellingen
├── bios/                  # PS1 BIOS bestanden
├── cache/
│   ├── gamelist.cache     # Game library cache
│   └── gamedb.cache       # Game database
└── memcards/              # Memory cards
```

**Library-scanning (in settings.ini):**
```ini
[GameList]
RecursivePaths = /mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PSX
```

**Game structure:**
```
/mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PSX/
├── a-m/
│   ├── Crash Bandicoot/
│   │   └── Crash Bandicoot (USA).cue
│   └── ...
└── n-z/
    ├── silent_hill/
    │   └── silent_hill.iso
    └── ...
```

**Belangrijke settings (settings.ini):**
```ini
[Main]
StartFullscreenUI = true          # Start in game library view
SetupWizardIncomplete = false     # Setup wizard afgerond
StartFullscreen = false           # GUI opent in windowed mode

[GameList]
RecursivePaths = /mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PSX

[BIOS]
SearchDirectory = bios            # Relatief pad naar BIOS

[Pad1]
Type = AnalogController           # Standaard controller
# + keyboard bindings (WASD + pijltjestoetsen)
```

**Preconf structuur:**
```
EMU-LAUNCHERS/preconf/duckstation/
├── settings.ini           # Met RecursivePaths ingevuld
└── bios/
    ├── scph1000.bin
    ├── scph1001.bin
    ├── scph5501.bin
    ├── scph7001.bin
    └── (30+ BIOS variants)
```

**Test:** ✅ Geslaagd (19 okt 2026)
- AppImage start correct
- Preconf wordt gekopieerd naar `~/.local/share/duckstation`
- Game library wordt automatisch gescand
- Games verschijnen zonder handmatig toe te voegen

---

## PS2 PCSX2 Configuratie

### Status: ✅ Geconfigureerd (19 okt 2026)

**Emulator:**
```
/mnt/VG_00/Portable.APPS/EMU/SONY/PS2/pcsx2-v2.8.2-x64-Qt.AppImage
```

**Config:**
```ini
[ps2]
title=PlayStation 2 (PS2)
emu=/mnt/VG_00/Portable.APPS/EMU/SONY/PS2/pcsx2-v2.8.2-x64-Qt.AppImage
args=-nogui -fullscreen -fastboot %ROM%
status=ok
userconf=~/.config/PCSX2
```

**Config-bestandslocatie:**
```
~/.config/PCSX2/
├── inis/
│   └── PCSX2.ini          # Hoofdinstellingen
├── bios/                  # PS2 BIOS bestanden
├── cache/
│   └── gamelist.cache     # Game library cache
└── memcards/              # Memory cards
```

**Library-scanning (in PCSX2.ini):**
```ini
[GameList]
RecursivePaths = /mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PS2
```

**Game structure:**
```
/mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PS2/
├── OutRun 2006 - Coast 2 Coast PS2 PAL/
│   └── OutRun 2006 - Coast 2 Coast (Europe).iso
├── Need for Speed - Carbon - Collector_s Edition PS2 PAL/
│   └── Need for Speed - Carbon (Europe).iso
├── Pitfall - The Lost Expedition PS2 NTSC/
│   └── Pitfall - The Lost Expedition (USA).iso
├── Fantastic 4 PS2 PAL/
│   └── Fantastic 4 (Europe).iso
└── X-Men Next Dimension PS2 PAL/
    └── XND.ISO
```

**Belangrijke settings (PCSX2.ini):**
```ini
[UI]
StartFullscreen = true            # Direct fullscreen
SetupWizardIncomplete = false     # Setup wizard afgerond

[GameList]
RecursivePaths = /mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PS2

[EmuCore]
EnableFastBoot = true            # Snel opstarten
```

**Preconf structuur:**
```
EMU-LAUNCHERS/preconf/pcsx2/
├── PCSX2.ini              # Met RecursivePaths ingevuld
└── bios/
    ├── scph39001.bin
    ├── scph10000.bin
    ├── PS2 Bios 30004R V6 Pal.bin
    └── (overige BIOS variants)
```

**Test:** ✅ Geslaagd (19 okt 2026)
- AppImage start correct
- Preconf wordt gekopieerd naar `~/.config/PCSX2`
- Game wordt gestart met correcte arguments

---

## PS3 RPCS3 Configuratie (referentie)

### Status: ✅ Geconfigureerd

**Config:**
```ini
[ps3]
title=PlayStation 3 (PS3)
emu=/mnt/VG_00/PUBLIC-LIBRARY/EMU/SONY/PSX3/rpcs3-v0.0.22-13538-c14e79f8_linux64.AppImage
args=--no-gui %ROM%
status=ok
accept_dir=1
```

**Let op:** `accept_dir=1` - RPCS3 accepteert een MAP als argument (niet ISO).

**Library:** RPCS3 gebruikt `~/.config/rpcs3/games.yml`:
```yaml
BCES01584: /mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PS3/BCES01584 - The Last of us/
BLES00876: /mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/PLAYSTATION/PS3/BLES00876-Toy Story 3/
```

**Game launch met ID (alternatief):**
```bash
rpcs3 --no-gui "BCES01584"
```
Vereist dat game in `games.yml` staat.

**Let op:** RPCS3 heeft preconf nodig met `games.yml` om library te delen.
Zie `preconf/rpcs3/` (nog niet aangemaakt).

---

## Vergelijking per emulator

| Eigenschap | PS1 (DuckStation) | PS2 (PCSX2) | PS3 (RPCS3) |
|------------|-------------------|-------------|-------------|
| **Config pad** | `~/.local/share/duckstation/` | `~/.config/PCSX2/` | `~/.config/rpcs3/` |
| **Config bestand** | `settings.ini` | `inis/PCSX2.ini` | `config.yml` |
| **Library bestand** | `settings.ini` + `cache/gamelist.cache` | `inis/PCSX2.ini` + `cache/gamelist.cache` | `games.yml` |
| **Library instelling** | `[GameList] RecursivePaths` | `[GameList] RecursivePaths` | YAML mapping |
| **ROM type** | ISO/CUE/CHD/MDS | ISO/CHE/CSO | MAP (folder) |
| **accept_dir** | 0 | 0 | 1 |
| **Game ID launch** | Nee | Nee | Ja (`%%RPCS3_GAMEID%%`) |

---

## Systeem Configureren

### Nieuw Sony-systeem toevoegen

1. Voeg sectie toe aan `emulation.conf`:
   ```ini
   [psp]
   title=PlayStation Portable (PSP)
   emu=/pad/naar/ppsspp.AppImage
   args=%ROM%
   status=ok
   userconf=~/.config/ppsspp
   ```

2. Maak wrapper-script in `sony/psp.sh`:
   ```bash
   #!/bin/bash
   export GAME_SYSTEM="psp"
   exec "$(dirname "$(readlink -f "$0")")/../emu-launch.sh"
   ```

3. Maak preconf map met standaard-config:
   ```bash
   mkdir -p preconf/ppsspp
   # Kopieer standaard config + BIOS/firmware
   ```

4. Test: `python3 game-gui-fork.py` → PSP verschijnt in carousel

### Emulator installeren (emu-install.sh)

Als `status=missing` of `emu=` leeg is, biedt de GUI aan om de emulator te
installeren via `emu-install.sh`.

---

## Troubleshooting

### "emulator ontbreekt"

Controleer `emulation.conf`:
```bash
grep -A5 "\[psx\]" emulation.conf
# emu= moet pad naar binary bevatten
# status= moet ok zijn
```

### "geen rom gevonden"

Controleer of game-map bestaat en ROM bevat:
```bash
ls -la /mnt/.../PLAYSTATION/PSX/Game\ Name/
```

### Preconf wordt niet gekopieerd

Controleer of `userconf=` ingesteld is:
```bash
grep "userconf=" emulation.conf
```

### Library niet bijgewerkt / games ontbreken

**DuckStation (PS1):**
```bash
# DuckStation GUI → Settings → Game List → Refresh
# Of verwijder cache en herstart:
rm ~/.local/share/duckstation/cache/gamelist.cache
```

**PCSX2 (PS2):**
```bash
# PCSX2 GUI → Settings → Game List → Refresh
# Of verwijder cache en herstart:
rm ~/.config/PCSX2/cache/gamelist.cache
```

**RPCS3 (PS3):**
```bash
# Handmatig games.yml bijwerken:
vim ~/.config/rpcs3/games.yml
# Of RPCS3 GUI → File → Scan for games
```

### BIOS ontbreekt

Zorg dat preconf bevat:
- PS1: `preconf/duckstation/bios/*.bin`
- PS2: `preconf/pcsx2/bios/*.bin`

Of kopieer handmatig naar de user-conf bios map.

---

## Gerelateerde Bestanden

- `emulation.conf` - Hoofdconfiguratie
- `emu-launch.sh` - Generieke launcher
- `emu-install.sh` - Emulator installer
- `preconf/` - Standaard-configs voor nieuwe gebruikers
- `../README.md` - Algemene game-launcher documentatie (Windows/Linux)
- `../../game-core/game-common.sh` - Core voor Windows/Linux games

## Zie ook

- **Windows/Linux games:** `../README.md` (LINUXLAUNCHERS)
- **Hooks:** `../../game-core/hooks/`
- **Tools:** `../../tools/`
