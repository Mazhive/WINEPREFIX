# 3rd-party Configuration Tools

Deze map bevat game-specifieke configuratie-tools die niet onderdeel zijn van de standaard Wine/winetricks provisioning, maar wel nodig zijn voor bepaalde games om correct te draaien.

## Structuur

```
tools/3rdparty/
├── R3_Setup_DX8.exe          # Rayman 3: Hoodlum Havoc - Ubisoft DX8 setup tool
└── README.md                 # Dit bestand
```

## Gebruik

### Via GUI (Game Launcher)
1. Selecteer de game in de carousel
2. Als de game een setup-tool heeft, verschijnt de **"Configure..."** knop in het opties-paneel
3. Klik op "Configure..." om de tool te starten in de game's Wine prefix

### Handmatig (terminal)
```bash
# Voorbeeld: Rayman 3 Setup
WINEPREFIX=/home/user/GAMEPREFIXES/Rayman3HoodlumHavoc/pfx wine64 /pad/tools/3rdparty/R3_Setup_DX8.exe
```

## Toevoegen van een nieuwe tool

1. **Plaats de tool** in `tools/3rdparty/` (bijv. `GameSetup.exe`)
2. **Update het launcher-script** van de game met metadata:
   ```bash
   export GAME_SETUP_TOOL="GameSetup.exe"
   export GAME_SETUP_TOOL_NAME="Game Setup"
   ```
3. **De GUI detecteert automatisch** de tool en toont de "Configure" knop

## Ondersteunde games

| Game | Tool | Doel |
|------|------|------|
| Rayman 3: Hoodlum Havoc | `R3_Setup_DX8.exe` | Resolutie, graphics quality, fullscreen/windowed, audio instellen |

## Opmerkingen

- Tools worden **async** gestart (non-blocking) — de GUI blijft responsief
- De tool draait in de **game's eigen Wine prefix** (`~/GAMEPREFIXES/<GAME_NAME>/pfx`)
- De prefix moet **al bestaan** (game min. 1x gestart) voordat de tool werkt
- Instellingen die de tool schrijft (bijv. `ubi.ini`) worden **overschreven** door de `rayman3_ubi_config` hook bij volgende start voor cross-monitor compatibiliteit