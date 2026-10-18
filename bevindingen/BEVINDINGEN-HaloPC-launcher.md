# BEVINDING — Halo: Combat Evolved (PC) — Launcher-bouw & prefix-verificatie

Datum: 2026-10-16.
Rol: **Launcher-Builder Agent** (uitvoering; analyse-overname uit
`BEVINDINGEN-HaloPC.md` — Diagnostiek-Agent, read-only).
Status: **launcher opgeleverd en live getest → spel start én sluit schoon af op een
verse win32-prefix zónder winetricks-componenten. Hypothese "Vervolg #1" van
`BEVINDINGEN-HaloPC.md` is bevestigd.**

---

## 1. Overgenomen recept (BEVINDINGEN-HaloPC.md)

| eigenschap | waarde |
|---|---|
| referentie-prefix | `/home/peter/GAMEPREFIXES/HALO-PC-origineel` (meetlat, **niet** gekopieerd) |
| `WINEARCH` | **win32** (`#arch=win32` in `system.reg`, regel 4) |
| Wine | `wine-11.0` |
| game-dir | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Halo-PC/` |
| exe | `halo.exe` (Halo PC v1.07, no-CD, PE32/i386) |
| werkende oneliner | `WINEARCH=win32 WINEPREFIX=... wine halo.exe -vidmode 1920,1080,60 -windowed` (cwd = game-map) |
| loaddll-bewijs | **géén** winetricks-component geladen (d3dx9/d3dcompiler/vcrun → grep 0) |
| dragend | (a) win32-arch, (b) game-eigen DLL's naast exe, (c) Wine builtins d3d9/dinput8/dsound/wined3d |
| ExitFlag | `HKCU\...\Microsoft Games\Halo` = `clean` (`user.reg:409-411`) — prefix aantoonbaar in gebruik |

## 2. Prefix-analyse (alleen lezen, niets gewijzigd)

- `system.reg:4` → `#arch=win32` ✓
- `user.reg:409-411` → `ExitFlag="clean"`, `FIRSTRUN=1`, `gamma=1` ✓
- `user.reg:833-861` → DllOverrides `*d3dx9_24..43`/`*d3dcompiler_43|47` = native,
  `*msvcm80/*msvcp80/*msvcr80/*vcomp` = native,builtin (winetricks-erfgoed, **niet dragend**)
- `winetricks.log` → `d3dx9`, `d3dcompiler_43`, `d3dcompiler_47`, `vcrun2005`
- Layout: **rauwe prefix** (geen `pfx/`-subdir) — core-conventie is `~/GAMEPREFIXES/<GAME_NAME>/pfx`

## 3. Core-verificatie (game-common.sh)

| onderwerp | bevinding |
|---|---|
| prefix-aanmaak | `WINEARCH="$PREFIX_ARCH" wineboot -i` (regel 445) → **verse** prefix op `~/GAMEPREFIXES/HaloPC/pfx`; conform AGENTS.md: geen kopie/link van de meetlat |
| cwd | `cd "${GAME_WORKDIR:-$GAME_DIR}"` (regel 972) = game-map ≡ werkende one-liner |
| argumentpad | `game_launch()` regel 1118: `wine "$GAME_EXE" "$@"`; keten `game_main "$@"` → `game_launch "$@"` |
| `--gui-flags` | `game_main()` regel 1257 checkt `$1` **vóór** alles → `game_main "$@" -vidmode ...` is veilig (user-args blijven op positie 1) |
| `GAME_WINE_EXTRA_ARGS` | **bestaat niet in de core** (slechts voorstel in `BEVINDINGEN-Myst2021Remake.md` §2, nooit geïmplementeerd; grep = 0 treffers). Args vóór `"${...}" "$@"` vereist een core-wijziging — bewust **niet** gedaan (buiten scope dunne launcher) |

## 4. Hooks-afweging

- `PROVISION_HOOKS=("install_vcrun2005")` → **bestaat niet** (hooks/ heeft alleen vcrun2008/2015/2019/2022).
- Volgens loaddll-bewijs worden díe winetricks-componenten niet geladen → **geen provisioning-hooks**.
  Dit implementeert letterlijk "Vervolg #1" van de bevinding: test op een **verse** win32-prefix.
- `install_halo_*`-hooks (directx_reg/dlloverrides/dxvk_conf/winver_xp) en `install_directplay`
  zijn níét gebruikt: ze staan niet in de werkende one-liner → één-variable-per-test (WERKWIJZE.md).

## 5. Opgeleverde launcher

Bestand: `template-scripts/game-launchers/LINUXLAUNCHERS/halopc.sh` (32 regels, `chmod +x`, `bash -n` → OK)

```bash
#!/usr/bin/env bash
set -euo pipefail
export GAME_NAME="HaloPC"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Halo-PC"
export GAME_EXE="$GAME_DIR/halo.exe"
export PREFIX_ARCH="win32"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Halo: Combat Evolved"
export GAME_ICON="halo.png"
export GAME_LAUNCHER="$(readlink -f "$0")"
# geen PROVISION_HOOKS / PRE_LAUNCH_HOOKS — zie §4
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@" -vidmode 1920,1080,60 -windowed
```

**Bug tijdens eerste testrun (gevonden + gefixt):** de eerste versie miste de
`source .../game-common.sh`-regel → `game_main: command not found` en directe exit.
Regel toegevoegd; tweede run OK.

Conform `.opencode/AGENTS.md`:
- shebang `#!/usr/bin/env bash` + `set -euo pipefail` ✓
- uitsluitend exports + `game_main`; geen gedupliceerde logica (modulariteit) ✓
- padresolutie via `readlink -f "$0"`; geen hardcoded `/home/...`-paden in het script ✓
- geen sudo/root ✓
- icoon: `gameicons/halo.png` aanwezig (exacte match op `GAME_ICON`) ✓
- GUI-registratie: `game-gui.py:209-214` leest `GAME_ICON`/`GAME_DISPLAY_NAME` regex-veilig uit
  `export ...="..."`-regels ✓

**Beoogde launch-pipeline:** `wine /…/Halo-PC/halo.exe -vidmode 1920,1080,60 -windowed`
vanuit de game-map, in `~/GAMEPREFIXES/HaloPC/pfx` (win32, wineboot -i, zonder winetricks).

## 6. Verificaties

### 6.1 Live-test — **UITGEVOERD, GESLAAGD**
Uitgevoerd als achtergrondproces (conform AGENTS.md):
```bash
nohup template-scripts/game-launchers/LINUXLAUNCHERS/halopc.sh > /tmp/halopc-test.log 2>&1 &
```

Resultaat (`/tmp/halopc-test.log`):
- `wineboot -i` → prefix aangemaakt op `/home/peter/GAMEPREFIXES/HaloPC/pfx`
- Provisioning-marker `.provisioned` = `1`; `system.reg` → `#arch=win32` ✓
- Shortcut: `/home/peter/Desktop/HaloPC.desktop` (icon `halo.png`) ✓
- Spel bereikte de renderer: `fixme:d3d:wined3d_device_apply_stateblock`,
  `fixme:d3d:state_linepattern_w ... OpenGL core contexts`, `Spelvenster verschenen (na 4s)`
- Niet-fatale meldingen identiek aan de meetlat: `Using profile path .`,
  `Failed to read data file header bitmaps/sounds`, `ddraw7_Initialize`, `wbemprox`

**Beslissend bewijs (verse prefix `HaloPC`):**
```
[Software\\Microsoft\\Microsoft Games\\Halo]
"ExitFlag"="clean"
"FIRSTRUN"=dword:00000001
"gamma"=dword:00000001
```
en `[Software\\Wine\\DllOverrides]` is **leeg** (geen winetricks-native-overrides).
→ Betekenis: het spel is in de verse prefix gestart **en schoon afgesloten**,
zonder d3dx9/d3dcompiler/vcrun2005. Dit bevestigt de conclusie + "Vervolg #1"
van `BEVINDINGEN-HaloPC.md`.

### 6.2 Overige
1. `.desktop`-test: shortcut aangemaakt; dubbelklik-gedrag nog handmatig te bevestigen.
2. GUI-carrousel: nog te bevestigen dat `Halo: Combat Evolved` met `halo.png` verschijnt.

## 7. Risico's / aandachtspunten

- **Videomode hardgecodeerd** (1920,1080,60) uit de werkende one-liner; andere resolutie vereist
  een aanpassing in de launcher (of toekomstige core-support voor `GAME_WINE_EXTRA_ARGS`).
- One-liner gebruikte `-windowed`; fullscreen-optie is daarmee geblokkeerd tenzij arg weggelaten wordt.
- Meetlat-prefix wordt **nooit** gebruikt als sjabloon; bij problemen is differentiatie t.o.v.
  `HALO-PC-origineel` de methode (WERKWIJZE.md).
