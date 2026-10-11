# BEVINDING — Worms World Party Remastered

Datum: 2026-10-10
Status: Analyse afgerond (read-only). Configuratie gecontroleerd via grep (geen langdurige Wine-run).
Bron: WERKWIJZE.md, bestaande bevindingen, template-scripts (launcher + hooks), feedback gebruiker.

## Conclusie

De gevraagde configuratie is **reeds volledig aanwezig** in de launcher en hooks. De implementatie voldoet aan alle gevraagde acties.

## Controle (grep-verificatie)

### Launcher: LINUXLAUNCHERS/wormsworldpartyremastered.sh
- `PROVISION_HOOKS` bevat: `install_dxvk`, `install_d3dx9`, `install_gamescope`, `disable_winebus`, `install_cnc_ddraw`, `install_virtual_desktop`, `set_graphics_resolution` ✓
- `GAME_GAMESCOPE="1"`, `GAME_GAMESCOPE_RES="1920x1080"` ✓
- `WINE_VIRTUAL_DESKTOP="1"`, `WINE_DESKTOP_W="1920"`, `WINE_DESKTOP_H="1080"` ✓

### Hook: install_cnc_ddraw.sh
- Download cnc-ddraw, plaats `ddraw.dll` in gamemap ✓
- Zoekt `ddraw.dll` in uitgepakt archief en kopieert naar `$GAME_DIR/ddraw.dll` ✓

### Hook: set_graphics_resolution.sh
- Schrijft `Graphics Width` en `Graphics Height` (REG_DWORD) naar `HKEY_CURRENT_USER\Software\Team17\Worms World Party\Options` ✓

## Vergelijking gevraagde acties vs. bestaande implementatie

| Gevraagde actie | Huidige implementatie | Status |
|---|---|---|
| Wine Virtual Desktop (emulate) + desktop size 1920x1080 | `WINE_VIRTUAL_DESKTOP=1`, `WINE_DESKTOP_W/H=1920x1080` | ✓ Aanwezig |
| Gamescope forceer `-w 1920 -h 1080 -f -- %command%` | `GAME_GAMESCOPE=1`, `GAME_GAMESCOPE_RES=1920x1080` | ✓ Aanwezig (game-common genereert equivalent) |
| Download cnc-ddraw.zip, plaats `ddraw.dll` in gamemap | Hook `install_cnc_ddraw.sh` downloadt v2.1.1.0, kopieert `ddraw.dll` naar `$GAME_DIR/ddraw.dll` | ✓ Aanwezig |
| winecfg Libraries → ddraw op Native | Effectief via lokale `ddraw.dll` in gamemap (override per executable) | ✓ Correcte aanpak |
| Registry Graphics Width/Height (Team17\Worms World Party\Options) op 1920x1080 | Hook `set_graphics_resolution.sh` schrijft REG_DWORD 1920/1080 | ✓ Aanwezig |

## PROVISION_HOOKS
```bash
PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "install_gamescope" "disable_winebus" "install_cnc_ddraw" "install_virtual_desktop" "set_graphics_resolution")
```

## Kritische punten (feedback) — teststrategie volgens WERKWIJZE

### 1. Gamescope + Wine Virtual Desktop (dubbele opsluiting)
- **Risico:** Dubbele virtuele desktop → venster-in-venster, muis-clipping, extra overhead.
- **Aanbeveling (één variabele per run):** Test eerst met Gamescope actief **én** `WINE_VIRTUAL_DESKTOP` uitgeschakeld vs. huidige setup. Kies één (Gamescope aanbevolen op Wayland).

### 2. DXVK + cnc-ddraw (dubbele vertaallaag)
- **Risico:** cnc-ddraw rendert DirectDraw zelf; DXVK vertaalt D3D9 → Vulkan. Kan artifacts/crashes geven bij 2D-game.
- **Aanbeveling (één variabele per run):** Probeer eerst **zonder** `install_dxvk` (alleen cnc-ddraw + Wined3D/OpenGL). Voeg DXVK pas toe bij rendering-problemen. Volg aftrekkende werkwijze.

### Verificatiepunten
- Muis-clipping/randen: bij dubbele VD → schakel WINE_VD uit als Gamescope actief.
- Crash menu→in-game (resolutiewissel): controleer registry `Graphics Width/Height` vs. ondersteunde aspect ratio.

## Bevinding
**Werkt het?** Configuratie is correct geïmplementeerd volgens de gevraagde procedure. Of het in praktijk stabiel draait, moet worden getest per variabele (bovenstaande punten) conform WERKWIJZE.md. De implementatie zelf is aanwezig en correct.
