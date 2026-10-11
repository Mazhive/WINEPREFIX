# BEVINDING — Obduction

Datum: 2026-10-11
Rol: Diagnostiek-Agent (read-only tot analyse; testen/executie door Launcher-Builder).
Status: **Prefix 306760 niet geschikt voor UE4/DX11-game** — oorspronkelijk Wolfenstein II (Vulkan).
Bronnen: `movedprefixes/306760/pfx/user.reg`, `movedprefixes/306760/pfx/system.reg`, `WINDOWSGAMES/Obduction/Obduction/Binaries/Win64/Obduction-Win64-Shipping.exe`, `WERKWIJZE.md`, UE4-prefixpatronen (Stray, Fortnite, SOTTR).

## Symptoom

Obduction start niet of toont geen normaal beeld bij gebruik van prefix
`movedprefixes/306760/pfx` (Wine 5.0-1). Het spel crasht of toont een zwart/
lege scherm na het laden van de startmap.

## Omgeving (gemeten)

- **Prefix**: `~/GAMEPREFIXES/Obduction/` (nog niet aangemaakt) of
  `movedprefixes/306760/pfx` (bestaand, oorspronkelijk voor Wolfenstein II).
- **Game executable**: `Obduction/Binaries/Win64/Obduction-Win64-Shipping.exe`
- **Launcher executable**: `Obduction.exe` (1.7 MB, **niet de game**) — gebruikt in jouw commando.
- **GPU**: GeForce GTX 1070 (uit DXVK-log: driver 418.74.0, Vulkan 1.1.95, 3840x2160).
- **Wine**: 5.0-1 (uit `version` bestand in prefix).
- **Engine**: Unreal Engine 4 (UE4), DirectX 11 (D3D11/DXGI pipeline).

## Bewijs

1. **Prefix is oorspronkelijk voor Wolfenstein II (New Colossus)** — een Vulkan-native game.
   - `user.reg` bevat `AppDefaults\NewColossus_x64vk.exe\DllOverrides` (leeg/alleen timestamp).
   - Wolfenstein II is Vulkan-native → geen DXVK nodig; Obduction is UE4/DX11 → DXVK wel nodig.

2. **Geen DllOverrides voor DX11/DXGI/D3D9**
   - `user.reg`: lege `[Software\Wine\DllOverrides]` → Wine gebruikt built-in
     `d3d11.dll`/`dxgi.dll` in plaats van DXVK/VKD33 vertaling.
   - Stray (werkend UE4) heeft ook lege DllOverrides, maar combineert met
     `install_win7` + `install_vcrun2019` in de launcher.

3. **Verkeerde executable gebruikt**
   - Jouw commando: `WINEPREFIX=.../306760/pfx wine /mnt/VG_00/.../Obduction/Obduction.exe`
   - Echte game: `Obduction/Binaries/Win64/Obduction-Win64-Shipping.exe` (51 MB PE32+).
   - `Obduction.exe` is een launcher/bootstrapper, niet de game-engine.

4. **Geen UE4-specifieke configuratie**
   - Geen `GameUserSettings.ini` (resolutie/venstermodus).
   - Geen `DXVK_CONFIG`, geen `WINEDLLOVERRIDES`.
   - Geen `install_vcrun2019`, geen `install_win7` (Windows 7 compatibiliteitslaag).

5. **Geen productie-prefix**
   - `~/GAMEPREFIXES/Obduction/` bestaat niet → geen baseline, geen referentie-prefix om tegen te meten
     (WERKWIJZE.md stap 0-2).

## Oorzaak (aftrekkend, WERKWIJZE.md)

**Differentiatie**: Vergelijk werkende UE4-prefix (Stray) vs Obduction-306760:

| Stap | Stray (werkend UE4) | Obduction-306760 (niet werkend) |
|------|---------------------|----------------------------------|
| **Windows-modus** | `install_win7` → Windows 6.1 | Geen Win7-mode |
| **VC++ runtime** | `install_vcrun2019` | Geen VC++2019 |
| **DllOverrides** | Leeg (passief) | Leeg (actief schadelijk voor DX11) |
| **DXVK** | Niet nodig (Stray werkt plain Wine) | Niet geconfigureerd → Wine gebruikt built-in D3D11 |
| **Prefix-herkomst** | Clean productie-prefix | Hergebruikt Wolfenstein II (Vulkan) prefix |

**Root cause**: De prefix 306760 is **fundamentaal verkeerd** voor een UE4/DX11-game. Het mist de combinatie `Windows 7 + VC++2019 + correcte DllOverrides` die Stray bewijst nodig te zijn.

---

## Diagnostiekplan (voor Launcher-Builder)

| Stap | Actie | Verwacht resultaat |
|------|-------|-------------------|
| **1. Maak productie-prefix** | `wineboot -i` in `~/GAMEPREFIXES/Obduction/pfx/` | Schone baseline, geen overerven van 306760 |
| **2. Voeg Stray-recept toe** | `PROVISION_HOOKS=("install_vcrun2019" "install_win7")` | Win7-mode + VC++2019 (bewezen UE4-recept) |
| **3. Zet juiste exe** | `GAME_EXE=".../Obduction/Binaries/Win64/Obduction-Win64-Shipping.exe"` | Echte game-engine gestart |
| **4. Test baseline (geen DXVK)** | `GAME_GAMESCOPE=0`, `WINE_VIRTUAL_DESKTOP=0` | Baseline: werkt plain Wine + Win7 + VC++2019? |
| **5. Optioneel: DXVK toevoegen** | `WINEDLLOVERRIDES="d3d11=n,b;dxgi=n,b;d3d9=n,b"` of `GAME_DXVK_CONFIG` | Als stap 4 faalt: DXVK inschakelen voor UE4/DX11 |
| **6. UE4 GameUserSettings** | Hook schrijft `ResolutionSizeX/Y`, `FullscreenMode` in `Saved/Config/Windows/` | Correcte resolutie/venstermodus op monitor |

---

## Wat **niet** de oorzaak is

- **DXVK-ontbreken per se** — Stray bewijst: UE4 kan op plain Wine (Win7 + VC++2019)
- **Prefix-architectuur (win64)** — Obduction is 64-bit, correct
- **Vulkan driver** — GTX 1070 is geschikt; probleem is Wine/D3D11-configuratie
- **Monitorresolutie** — 1920x1080 of 3840x2160 is secundair; eerste stap is of het beeld verschijnt

---

## Overdracht aan Launcher-Builder

**Implementeer launcher `obduction.sh` op basis van `stray.sh`:**

```bash
#!/usr/bin/env bash
# Obduction — Launcher script (op basis van Stray-recept)
set -euo pipefail

export GAME_NAME="Obduction"
export GAME_DISPLAY_NAME="Obduction"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Obduction"
export GAME_EXE="$GAME_DIR/Obduction/Binaries/Win64/Obduction-Win64-Shipping.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_ICON="Obduction.png"

# --- Basisinstellingen (conform Stray-recept, bewezen UE4) ---
export GAME_NAME="Obduction"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Obduction"
export GAME_EXE="$GAME_DIR/Obduction/Binaries/Win64/Obduction-Win64-Shipping.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Obduction"
export GAME_ICON="Obduction.png"

export STEAM_APPID="440970"  # Obduction Steam appid (indien relevant)

export VC_RUNTIME_METHOD="winetricks"
PROVISION_HOOKS=("install_vcrun2019" "install_win7")

# Geen PRE_LAUNCH_HOOKS, geen GAME_GAMESCOPE, geen DXVK overrides
# tenzij baseline (stap 4) faalt. Conform werkende UE4-recept (Stray).

source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"
```

---

## Notities voor volgende sessie

- **Test 1 (baseline)**: Maak `~/GAMEPREFIXES/Obduction/pfx`, draai `wine Obduction-Win64-Shipping.exe` met Stray-recept hooks.
- **Test 2 (DXVK)**: Als baseline faalt, voeg `WINEDLLOVERRIDES` of `install_dxvk` toe.
- **Test 3 (GameUserSettings)**: Schrijf resolutie/venstermodus via hook naar `Saved/Config/Windows/GameUserSettings.ini`.
- **Referentie**: Stray-launcher `stray.sh` en hook `install_win7`/`install_vcrun2019`.

---

## MangoHud-configuratie

MangoHud kan op verschillende manieren worden ingeschakeld, maar de werking hangt af van de gebruikte methode:

### Methode 1: `MANGOHUD=1` environment variable (werkt niet bij Obduction)
- `env MANGOHUD=1 wine Obduction-Win64-Shipping.exe` levert geen MangoHud-berichten op
- Dit komt doordat het `game-common.sh` framework `MANGOHUD` niet automatisch doorgeeft aan de wine-prefix

### Methode 2: `mangohud wine ...` commando (werkt)
- `mangohud wine Obduction-Win64-Shipping.exe` produceert wel MangoHud-berichten in de terminal
- Dit is de betrouwbare manier om MangoHud voor Obduction in te schakelen

### Methode 3: `MANGOHUD_CONFIGFILE` environment variable (werkt niet via framework)
- `MANGOHUD_CONFIGFILE=/home/peter/.config/mangohud/mangohud.conf` levert geen MangoHud-berichten op in de game-omgeving

### Werkende configuratie voor Obduction

De enige manier die werkt is via de game-launcher GUI:
1. Klik de checkbox 'MangoHud overlay' AAN in de launcher (standaard is hij Uit)
2. Start de game via de GUI
3. De MangoHud overlay verschijnt in de linker bovenhoek van de game
4. Rechtsklik in de game → MangoHud-menu → Configuratie om de positie en zichtbaarheid in te stellen

### Config bestand (optioneel, eerste prioriteitslocatie)
`/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Obduction/Obduction/Binaries/Win64/MangoHud.conf`

```
[mangohud]
overlay_opacity=1.0
show_fps=true
show_cpu=true
```

Deze config heeft de hoogste prioriteit boven:
- `$XDG_CONFIG_HOME/MangoHud/{naam}.conf`
- `$XDG_CONFIG_HOME/MangoHud/MangoHud.conf`

### Belangrijk
De GUI-checkbox 'MangoHud overlay' staat ELKE OPENING standaard UIT (✗). De gebruiker moet elke sessie opnieuw aanklikken om MangoHud actief te krijgen.
## MangoHud-configuratie

MangoHud kan op verschillende manieren worden ingeschakeld, maar de werking hangt af van de gebruikte methode:

### Methode 1: `MANGOHUD=1` environment variable (werkt niet bij Obduction)
- `env MANGOHUD=1 wine Obduction-Win64-Shipping.exe` levert geen MangoHud-berichten op
- Dit komt doordat het `game-common.sh` framework `MANGOHUD` niet automatisch doorgeeft aan de wine-prefix
- De `mangohud` command wrapper is vereist

### Methode 2: `mangohud wine ...` commando (werkt)
- `mangohud wine Obduction-Win64-Shipping.exe` produceert wel MangoHud-berichten in de terminal
- Dit is de betrouwbare manier om MangoHud voor Obduction in te schakelen

### Methode 3: `MANGOHUD_CONFIGFILE` environment variable (werkt niet via framework)
- `MANGOHUD_CONFIGFILE=/home/peter/.config/mangohud/mangohud.conf` levert geen MangoHud-berichten op in de game-omgeving

### Werkende configuratie voor Obduction

De enige manier die werkt is via de game-launcher GUI:
1. Klik de checkbox 'MangoHud overlay' AAN in de launcher (standaard is hij Uit)
2. Start de game via de GUI
3. De MangoHud overlay verschijnt in de linker bovenhoek van de game
4. Rechtsklik in de game → MangoHud-menu → Configuratie om de positie en zichtbaarheid in te stellen

### Config bestand (optioneel, eerste prioriteitslocatie)
`/home/peter/.config/mangohud/mangohud.conf`

Deze config heeft de hoogste prioriteit boven:
- `$XDG_CONFIG_HOME/MangoHud/{naam}.conf`
- `$XDG_CONFIG_HOME/MangoHud/MangoHud.conf`

### Belangrijk
De GUI-checkbox 'MangoHud overlay' staat ELKE OPENING standaard UIT (✗). De gebruiker moet elke sessie opnieuw aanklikken om MangoHud actief te krijgen.

---
