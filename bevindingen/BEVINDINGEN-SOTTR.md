# BEVINDINGEN — Shadow of the Tomb Raider (SOTTR)

## Samenvatting
Shadow of the Tomb Raider draait stabiel op **GE-Proton 11-7** met de NFS-share game folder (`/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Tombraider.SOTTR`) en een lokaal, vers aangemaakt prefix in `~/GAMEPREFIXES/SOTTR/`.

De oorspronkelijke fout **"Unable to load bigfile bigfile.000!"** werd veroorzaakt door een verkeerde werkmap (CWD) bij de handmatige Proton-run. De game laadt zijn `.tiger` bigfile-packs relatief aan de CWD, niet relatief aan de executable.

---

## Root Cause Analyse

### Foutieve run (eerste poging)
```bash
# Startte vanuit /mnt/VG_00/.../WINEPREFIX (verkeerde CWD)
STEAM_COMPAT_DATA_PATH=~/GAMEPREFIXES/CODEXSOTTR proton run /pad/naar/SOTTR.exe
```
**Game log toonde:**
```
[Main] Current directory: Z:\mnt\VG_00\PUBLIC-LIBRARY\PRE-INSTALLED-GAMES\WINEPREFIX
[Main] Working directory: Z:\mnt\VG_00\PUBLIC-LIBRARY\PRE-INSTALLED-GAMES\WINEPREFIX
[ASSERT] Fatal error: Unable to open bigfile bigfile.000!
```

### Correcte run (werkend)
```bash
cd "/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Tombraider.SOTTR" && \
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam" \
STEAM_COMPAT_DATA_PATH="$HOME/GAMEPREFIXES/SOTTR/compatdata/750920" \
STEAM_COMPAT_INSTALL_PATH="$PWD" \
STEAM_COMPAT_APP_ID=750920 SteamAppId=750920 \
"$HOME/.steam/root/compatibilitytools.d/GE-Proton11-7/proton" waitforexitandrun "./SOTTR.exe"
```
**Game log toont nu:**
```
[Main] Current directory: M:\Tombraider.SOTTR
[Main] Working directory: M:\Tombraider.SOTTR
[Main] Starting Tomb Raider v1.0 build 292.0_64
... (geen bigfile errors, game draait tot menu)
```

### Waarom dit werkt
1. **`cd "$GAME_DIR"`** — replica wat Steam doet; CWD = game folder
2. **`STEAM_COMPAT_INSTALL_PATH="$PWD"`** — Proton gebruikt dit voor drive-mapping en game-id detectie
3. **`STEAM_COMPAT_DATA_PATH=.../compatdata/750920`** — numerieke appid zodat ProtonFixes `get_game_id()` niet crasht (IndexError)
4. **`waitforexitandrun`** — wacht op wineserver shutdown, dan run (correcter dan `run` voor compatdata tracking)

---

## Geteste Combinaties

| Prefix | Game Folder | Exit Code | Bigfile Errors | Status |
|--------|-------------|-----------|----------------|--------|
| `SOTTR-CODEX` | CODEX (`/mnt/disk_3tb/...`) | 0 (clean) | 0 | ✅ Werkt |
| `SOTTR` | NFS (`/mnt/VG_00/.../Tombraider.SOTTR`) | 124 (timeout = draaide) | 0 | ✅ Werkt |

**Beide combinaties werken** mits de CWD en `STEAM_COMPAT_INSTALL_PATH` correct zijn.

---

## Prefix Kwaliteit

| Prefix | Structuur | `d3dcompiler_47` | `version` bestand | Beoordeling |
|--------|-----------|------------------|-------------------|-------------|
| `CODEXSOTTR` | Clean (geen nested pfx) | ✅ Ja | ❌ Nee | Goed, maar geen version marker |
| `SOTTR-CODEX` | **Nested pfx** (`pfx/pfx/...`) | ❌ Nee | ✅ Ja | Suboptimaal (provisioning bug) |
| `SOTTR` | **Nested pfx** (`pfx/pfx/...`) | ❌ Nee | ✅ Ja | Suboptimaal (provisioning bug) |

**Advies:** Gebruik een **vers, clean prefix** via de boilerplate (`wineboot -i` + hooks) in plaats van de bestaande geneste prefixes.

---

## Actieplan voor Launcher

### 1. Maak launcher script `sottr.sh`
Locatie: `template-scripts/game-launchers/sottr.sh` (en kopie in `LINUXLAUNCHERS/sottr.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

export GAME_NAME="SOTTR"
export GAME_DISPLAY_NAME="Shadow of the Tomb Raider"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Tombraider.SOTTR"
export GAME_EXE="$GAME_DIR/SOTTR.exe"
export GAME_ICON="sottr.png"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="750920"

# Optioneel: hooks indien nodig
# export PROVISION_HOOKS=("install_vcrun2019")

# Laad de centrale core-logica (werkt vanuit zowel game-launchers/ als LINUXLAUNCHERS/)
source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"
```

**Let op:** Het pad naar `game-common.sh` is `../../game-core/` omdat de launcher in `LINUXLAUNCHERS/` (submap van `game-launchers/`) staat. De originele boilerplate voorbeeld had `../game-core/` wat alleen werkt vanuit `game-launchers/`.

### 2. Voer eerste run uit (provisioning)
```bash
chmod +x template-scripts/game-launchers/sottr.sh
template-scripts/game-launchers/sottr.sh
```
Dit doet automatisch:
- `wineboot -i` → verse prefix in `~/GAMEPREFIXES/SOTTR/pfx`
- Provision hooks (indien geconfigureerd)
- `compatdata/750920/pfx` symlink aanmaken
- `.provisioned` marker schrijven
- Game starten met correcte CWD en env vars

### 3. Desktop shortcut test
Na eerste run: controleer of `~/Desktop/Shadow of the Tomb Raider.desktop` bestaat en werkt.

### 4. Optionele hooks evaluatie
- `install_vcrun2019` — als game crasht op VC++ runtime
- `install_dxvk` / `install_vkd3d` — voor DX12 performance
- `disable_winebus` — als toetsenbord/muis input problemen geeft (zoals bij Cyberpunk)
- `install_gamescope` — voor Wayland/AMD fullscreen fixes

---

## Command voor Handmatige Test (NFS versie)

```bash
cd "/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Tombraider.SOTTR" && \
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam" \
STEAM_COMPAT_DATA_PATH="$HOME/GAMEPREFIXES/SOTTR/compatdata/750920" \
STEAM_COMPAT_INSTALL_PATH="$PWD" \
STEAM_COMPAT_APP_ID=750920 SteamAppId=750920 \
"$HOME/.steam/root/compatibilitytools.d/GE-Proton11-7/proton" waitforexitandrun "./SOTTR.exe"
```

**Vereiste voorbereiding (éénmalig):**
```bash
mkdir -p "$HOME/GAMEPREFIXES/SOTTR/compatdata/750920"
ln -sf "$HOME/GAMEPREFIXES/SOTTR/pfx" "$HOME/GAMEPREFIXES/SOTTR/compatdata/750920/pfx"
touch "$HOME/GAMEPREFIXES/SOTTR/compatdata/750920/tracked_files"
```

---

## Conclusie
De game is **volledig speelbaar** via GE-Proton 11-7 met de NFS-share game folder. De boilerplate launcher zal bij eerste run een clean prefix aanmaken en de game correct starten. Geen afhankelijkheid van `movedprefixes` of bestaande `compatdata` mappen.

**Volgende stap:** Launcher script `sottr.sh` aanmaken en testen.

---

## Additionele Opmerking: Icon Bestanden

**Alle icon bestanden in `gameicons/` moeten `.png` formaat zijn.** Dit is een harde eis van de boilerplate (zie `game-common.sh` icon matching logica en desktop shortcut generatie).

### Conversie Script
Er staat een conversie script in de `gameicons/` map:
```
template-scripts/game-launchers/gameicons/jpeg2png.py
```

**Gebruik:**
```bash
cd template-scripts/game-launchers/gameicons/
python3 jpeg2png.py -d .
```

Dit script:
- Converteert `.jpg`, `.jpeg`, `.webp`, `.bmp`, `.tiff` naar `.png`
- Maakt achtergrond transparant (gebaseerd op hoekpixel kleur met tolerantie)
- Verwijdert het originele bestand na succesvolle conversie
- Slaat `.png` bestanden over

**Voor SOTTR:** Er was **geen `sottr.png` in `gameicons/`**. De icon is geëxtraheerd uit de game folder (`SOTTR-2.ico` frame 7, 256x256) en geconverteerd naar PNG.

### Icon Beleid (Nieuwe Regel)

**Als een icon bestand bestaat in de game folder:**
1. Extract de beste resolutie (bijv. `.ico` frame met hoogste resolutie, of `.png`/`.jpg`)
2. Converteer naar `.png` (256x256 of 512x512, transparante achtergrond)
3. Plaats in `template-scripts/game-launchers/gameicons/<GAME_NAME>.png`

**Als GEEN icon bestand in de game folder bestaat:**
- **Vereist:** Lever een `sottr.png` aan (256x256 of 512x512 PNG, transparante achtergrond)
- Plaats in `template-scripts/game-launchers/gameicons/`
- Zonder icon toont de desktop shortcut en GUI een generiek/leeg icoon

**Voor SOTTR toegepast:** `SOTTR-2.ico` frame 7 (256x256 PNG) geëxtraheerd en geplaatst als `gameicons/sottr.png`. Desktop shortcut bijgewerkt met `Icon=` regel.