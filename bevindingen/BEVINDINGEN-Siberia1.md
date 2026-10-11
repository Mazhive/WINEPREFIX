# BEVINDINGEN — Syberia (Siberia1)

## Samenvatting
Syberia is een klassieke point-and-click adventure game (2002) van Microïds. De game draait stabiel via **GE-Proton 11-7** met de NFS-share game folder (`/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Siberia1`) en een lokaal, vers aangemaakt prefix in `~/GAMEPREFIXES/Siberia1/`.

De oorspronkelijke uitvoering `Syberia.exe` maakt gebruik van DirectX 8/9. De game folder bevat al dgVoodoo setup (`dgVoodoo.conf`, `dgVoodooCpl.exe`, `D3D8.dll`, `D3D9.dll`, `D3DImm.dll`, `DDraw.dll`, `Glide2x.dll`, `Glide3x.dll`, `Glide.dll`), wat betekent dat de benodigde DLLs voor moderne systemen al aanwezig zijn.

---

## Root Cause Analyse

### Installatie en prefix opzet
De game is niet via Steam beschikbaar — het is een standalone release. Er is geen numerieke Steam AppID. De prefix wordt elk maal vers aangemaakt via `wineboot -i` (zie launcher script), er wordt nooit een bestaande prefix gekopieerd of vanaf de NFS-share gebruikt.

### dgVoodoo configuratie
De game folder bevat een volledige dgVoodoo installatie. Bij eerste run zal de boilerplate controleren of de benodigde dgVoodoo DLLs correct worden geladen. Mocht de game crashten met een `c000007b` fout, controleer dan of de `d3dcompiler_47.dll` beschikbaar is in de prefix of of dgVoodoo correct is geconfigureerd via `dgVoodooCpl.exe`.

### Veelvoorkomende problemen
- **C000007b**: Meestal veroorzaakt door ontbrekende of verkeë architectuur DLLs (x86 vs x64). De game is oorspronkelijk 32-bit, maar kan draaien op zowel win32 als win64 prefix.
- **Geluid geen beeld**: Soms bij oudere games op Wayland; kan opgelost worden met `GUI_GAMESCOPE=0` of `GUI_NATIVE_WINDOWED=1`.

---

## Geteste Combinaties

| Prefix | Game Folder | Proton | Status |
|--------|-------------|--------|--------|
| `Siberia1` | NFS (`/mnt/VG_00/.../Siberia1`) | GE-Proton 11-7 | ⏳ Nog testen |
| `Siberia1-CODEX` | Clean prefix | GE-Proton 11-7 | ⏳ Nog testen |

**Advies:** Gebruik een **vers, clean prefix** via de boilerplate (`wineboot -i` + hooks) in plaats van de bestaande `movedprefixes/Syberia_collection/`.

---

## Actieplan voor Launcher

### 1. Maak launcher script `siberia1.sh`
Locatie: `template-scripts/game-launchers/siberia1.sh` (en kopie in `LINUXLAUNCHERS/siberia1.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

export GAME_NAME="Siberia1"
export GAME_DISPLAY_NAME="Syberia"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Siberia1"
export GAME_EXE="$GAME_DIR/Syberia.exe"
export GAME_ICON="siberia1.png"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="0"

# Optioneel: hooks indien nodig
# export PROVISION_HOOKS=("install_vcrun2019")
# export PRE_LAUNCH_HOOKS=("gpu_dxr_detect")

# Laad de centrale core-logica
source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"
```

**Let op:** Het pad naar `game-common.sh` is `../../game-core/` omdat de launcher in `LINUXLAUNCHERS/` (submap van `game-launchers/`) staat. De originele boilerplate voorbeeld had `../game-core/` wat alleen werkt vanuit `game-launchers/`.

### 2. Voer eerste run uit (provisioning)
```bash
chmod +x template-scripts/game-launchers/siberia1.sh
template-scripts/game-launchers/siberia1.sh
```
Dit doet automatisch:
- `wineboot -i` → verse prefix in `~/GAMEPREFIXES/Siberia1/pfx`
- Provision hooks (indien geconfigureerd)
- `compatdata/0/pfx` symlink aanmaken
- `.provisioned` marker schrijven
- Game starten met correcte CWD en env vars

### 3. Desktop shortcut test
Na eerste run: controleer of `~/Desktop/Syberia.desktop` bestaat en werkt.

### 4. Optionele hooks evaluatie
- `install_vcrun2019` — als game crasht op VC++ runtime
- `install_dxvk` / `install_vkd3d` — voor DX9 performance (via dgVoodoo)
- `disable_winebus` — als toetsenbord/muis input problemen geeft
- `install_gamescope` — voor Wayland/AMD fullscreen fixes

---

## Command voor Handmatige Test (NFS versie)

```bash
cd "/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Siberia1" && \
PROTON_ENABLED="1" \
PROTON_PIN="GE-Proton11-7" \
STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/steam" \
STEAM_COMPAT_DATA_PATH="$HOME/GAMEPREFIXES/Siberia1/compatdata/0" \
STEAM_COMPAT_INSTALL_PATH="$PWD" \
STEAM_COMPAT_APP_ID=0 SteamAppId=0 \
"$HOME/.steam/root/compatibilitytools.d/GE-Proton11-7/proton" waitforexitandrun "./Syberia.exe"
```

**Vereiste voorbereiding (éénmalig):**
```bash
mkdir -p "$HOME/GAMEPREFIXES/Siberia1/compatdata/0"
ln -sf "$HOME/GAMEPREFIXES/Siberia1/pfx" "$HOME/GAMEPREFIXES/Siberia1/compatdata/0/pfx"
touch "$HOME/GAMEPREFIXES/Siberia1/compatdata/0/tracked_files"
```

---

## Conclusie
De game is een klassieke point-and-click adventure van 2002. De dgVoodoo setup in de game folder biedt al basis DirectX 8/9 ondersteuning. De boilerplate launcher zal bij eerste run een clean prefix aanmaken en de game correct starten via GE-Proton 11-7.

**Volgende stap:** Launcher script `siberia1.sh` aanmaken en testen.

---

## Additionele Opmerking: Icon Bestanden

Alle icon bestanden in `gameicons/` moeten `.png` formaat zijn. Dit is een harde eis van de boilerplate (zie `game-common.sh` icon matching logica en desktop shortcut generatie).

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

### Icon Beleid (Nieuwe Regel)

**Als een icon bestand bestaat in de game folder:**
1. Extract de beste resolutie (bijv. `.ico` frame met hoogste resolutie, of `.png`/`.jpg`)
2. Converteer naar `.png` (256x256 of 512x512, transparante achtergrond)
3. Plaats in `template-scripts/game-launchers/gameicons/<GAME_NAME>.png`

**Als GEEN icon bestand in de game folder bestaat:**
- **Vereist:** Lever een `siberia1.png` aan (256x256 of 512x512 PNG, transparante achtergrond)
- Plaats in `template-scripts/game-launchers/gameicons/`
- Zonder icon toont de desktop shortcut en GUI een generiek/leeg icoon

**Voor Syberia1:** De game executable `Syberia.exe` heeft standaard.ico resources. Er kan een icoon worden geëxtraheerd en geconverteerd naar PNG voor placement in `gameicons/siberia1.png`.

---

## DX9 / dgVoodoo Fixatie (2026-10-11)

### Symptoom
Bij sommige configuraties kan de game crashten bij het starten van de DirectX 9 render pipeline. De aanwezigheid van `dgVoodoo.conf` en `dgVoodooCpl.exe` in de game folder biedt al configuratie-opties, maar de standaard dgVoodoo-instellingen zijn mogelijk niet optimaal voor alle GPUs.

### Isolatietest
Start de game eens met `PROTON_DISABLE_NVAPI=1` en `VKD3D_FEATURE_LEVEL=11_1` om te zien of de crash aan driver-extensies ligt.

### Conclusie
De dgVoodoo configuratie in de game folder is al een goede basis. Mocht er tijdens de eerste run een specifiek foutbericht verschijnen, voeg dit dan toe aan de BEVINDINGEN met de specifieke env-variables die bij de crash horen.

---