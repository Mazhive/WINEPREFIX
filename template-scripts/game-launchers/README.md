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

# Provision hooks (alleen bij verse prefix)
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
| `PROVISION_HOOKS` | Array met hook-namen voor verse prefix setup |
| `PRE_LAUNCH_HOOKS` | Array met hook-namen voor bij elke start |
| `GAME_SETUP_TOOL` | Bestandsnaam van 3rd-party tool in `tools/3rdparty/` |
| `GAME_SETUP_TOOL_NAME` | Weergavenaam voor GUI knop |

## Hooks

Hooks staan in `game-core/hooks/` en worden geladen via naam:

- **Provision hooks** (1x per verse prefix): `install_dxvk`, `install_d3dx9`, `install_vcrun2019`, `game_vcrun2019`, etc.
- **Pre-launch hooks** (elke start): `game_steam_registry`, `game_ubi_config`, `wacom-detect`, etc.

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