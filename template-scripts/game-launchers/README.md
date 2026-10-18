# Game Launchers (LINUXLAUNCHERS)

Deze map bevat alle Linux launcher-scripts voor Windows games die via Wine draaien.

## Structuur

```
game-launchers/
├── gameicons/                 # Game iconen (PNG/JPG)
│   ├── backup.icons/          # Backup van iconen
│   └── *.png                  # Iconen per game
├── LINUXLAUNCHERS/            # Launcher scripts (.sh)
│   ├── *.sh                   # Per-game launcher (bijv. rayman3hoodlumhavoc.sh)
│   └── backup_launchers/      # Oudere versies van launchers
└── README.md                  # Dit bestand
```

## Launcher Script Anatomy

Elk launcher-script is een "dun" script dat variabelen exporteert en `game_main` aanroept:

```bash
#!/bin/bash
export GAME_NAME="GameName"
export GAME_DIR="/pad/naar/game"
export GAME_EXE="$GAME_DIR/Game.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

export VC_RUNTIME_METHOD="winetricks"
export STEAM_APPID="12345"

# Pre-provision hooks (VÓÓR wineboot -i, alleen bij verse prefix)
PRE_PROVISION_HOOKS=("install_wine32")

# Provision hooks (NA wineboot -i, alleen bij verse prefix)
PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "game_vcrun2019")

# Pre-launch hooks (bij ELKE start)
PRE_LAUNCH_HOOKS=("game_steam_registry" "game_ubi_config")

# Optioneel: 3rd-party configuratie-tool (voor GUI "Configure" knop)
export GAME_SETUP_TOOL="GameSetup.exe"
export GAME_SETUP_TOOL_NAME="Game Setup"

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
```

## Belangrijke Variabelen

| Variabele | Doel |
|-----------|------|
| `GAME_NAME` | Unieke identifier (wordt gebruikt voor prefix map, config keys) |
| `GAME_DIR` | Installatiepad van de game (op NFS share) |
| `GAME_EXE` | Volledig pad naar de .exe |
| `PREFIX_ARCH` | `win64` (aanbevolen) of `win32` |
| `SCRIPT_VERSION` | Versie voor provisioning cache invalidatie |
| `VC_RUNTIME_METHOD` | `winetricks` of `redist` |
| `STEAM_APPID` | Steam AppID voor ProtonFixes herkenning |
| `PRE_PROVISION_HOOKS` | Array met hook-namen die VÓÓR `wineboot -i` lopen (verse prefix) |
| `PROVISION_HOOKS` | Array met hook-namen voor verse prefix setup (na `wineboot -i`) |
| `PRE_LAUNCH_HOOKS` | Array met hook-namen voor bij elke start |
| `GAME_SETUP_TOOL` | Bestandsnaam van 3rd-party tool in `tools/3rdparty/` |
| `GAME_SETUP_TOOL_NAME` | Weergavenaam voor GUI knop |

## Hooks

Hooks staan in `game-core/hooks/` en worden geladen via naam. Elke module
definieert `hook_run()`. Er zijn **drie fasen**, in deze volgorde:

| Fase | Variabele | Wanneer | Voorbeeld |
|------|-----------|---------|-----------|
| 1. Pre-provision | `PRE_PROVISION_HOOKS` | Vóór `wineboot -i`, alleen bij verse prefix | `install_wine32` |
| 2. Provision | `PROVISION_HOOKS` | Ná `wineboot -i`, alleen bij verse prefix | `install_dxvk`, `install_d3dx9`, `install_vcrun2019` |
| 3. Pre-launch | `PRE_LAUNCH_HOOKS` | Bij **elke** start, vóór `game_launch` | `game_steam_registry`, `wacom-detect` |

- **Pre-provision** gebruik je voor checks die de prefix-aanmaak zelf moeten
  bewaken — bijv. `install_wine32`, dat vóór `wineboot -i` controleert of 32-bit
  Wine beschikbaar is voor een `win32`-prefix en anders een popup toont. Een
  falende hook breekt de provisioning af.
- **Provision** en **pre-launch** werken met dezelfde module-mechaniek; het
  per-game script kiest welke het nodig heeft. Pre-launch-hooks moeten strikt
  idempotent zijn (ze lopen bij elke start).

### Verifiëren dat een hook-fase echt draait

Een `*_HOOKS`-variabele die de core **niet** dispatcht, is onzichtbaar dood: het
script start gewoon, maar de hook wordt nooit uitgevoerd. Zo controleer je dat
een fase bestaat (voorkomt het opnieuw uitzoeken van een dode fase):

```bash
# Elke fase moet in game-common.sh voorkomen:
grep -nE 'PRE_PROVISION_HOOKS|PRE_PROV_HOOKS|PROVISION_HOOKS|PRE_LAUNCH_HOOKS' \
  template-scripts/game-core/game-common.sh
```

Verwacht (de core flattent de arrays in `game_init`):

| Fase | In `game_init` | Loop in |
|------|----------------|---------|
| Pre-provision | `PRE_PROVISION_HOOKS` → `PRE_PROV_HOOKS` | `game_provision` (vóór `_provision_fresh`) |
| Provision | `PROVISION_HOOKS` → `HOOKS` | `_provision_fresh` (na `wineboot -i`) |
| Pre-launch | `PRE_LAUNCH_HOOKS` → `PRE_HOOKS` | `game_main` (vóór `game_launch`) |

Ontbreekt een fase in de core, dan is de bijbehorende variabele in een launcher
een no-op.

## 3rd-party Configuratie Tools

Sommige games hebben een eigen setup-tool (bijv. Ubisoft's `R3_Setup_DX8.exe` voor Rayman 3). Deze worden:

1. **Geplaatst** in `tools/3rdparty/`
2. **Geregistreerd** in het launcher-script via `GAME_SETUP_TOOL`
3. **Gestart** via de GUI "Configure" knop (async, in game's prefix)

Zie `tools/3rdparty/README.md` voor details.

## Nieuwe Game Toevoegen

1. Maak launcher script aan in `LINUXLAUNCHERS/` (kopieer bestaand als template)
2. Voeg metadata toe aan launcher script:
   ```bash
   export GAME_DISPLAY_NAME="Game Naam"
   export GAME_ICON="GameIcon.png"
   ```
3. Zet icon in `gameicons/` (bestandsnaam = `GAME_ICON` waarde)
4. Test: `python3 game-gui.py` → game verschijnt in carousel
5. Eerste start: provisioning loopt automatisch (DXVK, VC++, etc.)

**Legacy fallback:** Games zonder `GAME_DISPLAY_NAME`/`GAME_ICON` gebruiken de oude `DISPLAY_NAMES`/`ICON_OVERRIDES` dicts in `game-gui.py` (leeg by default).

## Backup & Versies

- `backup_launchers/` bevat oudere versies van launchers
- `gameicons/backup.icons/` bevat oudere iconen
- Hoofdmap `backup/` (bovenin template-scripts) bevat volledige snapshots