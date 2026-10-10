# BEVINDING — Worms World Party Remastered

Datum: 2026-10-10
Status: Analyse afgerond (read-only). Acties uit opdracht zijn reeds geïmplementeerd in de bestaande launcher/hooks.
Bron: WERKWIJZE.md, bestaande bevindingen (BEVINDINGEN-WormsWorldPartyRemastered.md), template-scripts (launcher + hooks).

## Conclusie

De gevraagde configuratie is **reeds volledig aanwezig** in:
- `template-scripts/game-launchers/LINUXLAUNCHERS/wormsworldpartyremastered.sh`
- `template-scripts/game-launchers/wormsworldpartyremastered.sh`
- Hooks: `install_cnc_ddraw.sh`, `set_graphics_resolution.sh`, `install_gamescope.sh`, `install_virtual_desktop.sh` (via colinmcrea4_virtual_desktop niet direct; virtual desktop wordt via WINE_VIRTUAL_DESKTOP ingesteld), `install_dxvk.sh`, `install_d3dx9.sh`, `disable_winebus.sh`

Er hoeft **niets** toegevoegd te worden. Deze agent schrijft geen launchers/.sh-bestanden (regel nageleefd).

## Vergelijking gevraagde acties vs. bestaande implementatie

| Gevraagde actie | Huidige implementatie | Opmerking |
|---|---|---|
| Wine Virtual Desktop → Emulate a virtual desktop | `WINE_VIRTUAL_DESKTOP="1"`, `WINE_DESKTOP_W="1920"`, `WINE_DESKTOP_H="1080"` | Ingesteld in beide launcher-versies. |
| Detecteer video resolutie, zet desktop size naar schermresolutie | `GAME_GAMESCOPE_RES="1920x1080"` + WINE desktop 1920x1080 | Expliciet op 1920x1080 gezet (reproduceerbaar). Game-common kan ook auto-detecteren via xrandr indien niet gezet. |
| Forceer gamescope `-w 1920 -h 1080 -f -- %command%` | `GAME_GAMESCOPE="1"`, `GAME_GAMESCOPE_RES="1920x1080"` | game-common genereert `gamescope -f -W 1920 -H 1080 --` (equivalent). Alleen actief op Wayland + gamescope aanwezig. |
| Download nieuwste cnc-ddraw.zip, plaats `ddraw.dll` in map van Worms World Party Remastered | Hook `install_cnc_ddraw.sh` downloadt `cnc-ddraw_v2.1.1.0.zip` van GitHub, extraheert en kopieert `ddraw.dll` naar `$GAME_DIR/ddraw.dll` | cnc-ddraw v2.1.1.0 is de huidige versie in de hook. Plaatsing in de gamemap zorgt dat Wine die `ddraw.dll` native laadt (override per executable). |
| `winecfg` → Libraries → voeg `ddraw` toe en zet op Native | Effectief bereikt via lokale `ddraw.dll` in gamemap | Geen globale override nodig; lokaal bestand heeft voorrang. Dit is de juiste, minimale aanpak voor deze game. |
| `wine regedit` → `HKEY_CURRENT_USER\Software\Team18\Worms World Party\Options` (of Team17) → `Graphics Width/Height` op monitorresolutie (hex/dec) | Hook `set_graphics_resolution.sh` schrijft naar `HKEY_CURRENT_USER\Software\Team17\Worms World Party\Options` met `REG_DWORD` waarden `1920`/`1080` | Pad komt overeen met referentie (`Team17DigitalLTD`/`Team17` varianten komen voor; de hook gebruikt Team17-formaat zoals in bestaande implementatie). Hook verifieert na schrijven. |

## PROVISION_HOOKS (huidige launcher)

```bash
PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "install_gamescope" "disable_winebus" "install_cnc_ddraw" "install_virtual_desktop" "set_graphics_resolution")
```

Deze dekking komt overeen met referentie (DXVK + d3dx9) én voegt de gevraagde cnc-ddraw + resolutie + virtual desktop + gamescope toe.

## Validatie tegen WERKWIJZE.md

- **Read-only**: alleen gelezen, niets gekopieerd uit movedprefixes, niets gewijzigd.
- **Premisse**: referentie `movedprefixes/32.bit.worms.worldparty/pfx` bestaat (win64/WoW64, DXVK, d3dcompiler_43+d3dx9). Huidige aanpak (win64 + install_dxvk + install_d3dx9) sluit hierop aan.
- **Valkuil 2 (fault-adres)**: bij testen moet crash-adres worden vastgelegd, niet alleen "crash". (Opmerking voor verificatie, niet uitgevoerd door deze agent.)
- **Eén variabele per run**: verificatiestappen in bestaande bevindingen blijven van toepassing.

## Bevinding

De gevraagde acties zijn reeds geïmplementeerd. De bestaande oplossing is consistent met de referentie-analyse en de WERKWIJZE. Er is geen aanvullende actie nodig vanuit diagnostiek.

