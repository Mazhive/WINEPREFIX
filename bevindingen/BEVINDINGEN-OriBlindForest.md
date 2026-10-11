# BEVINDINGEN — Ori and the Blind Forest (BF)

Werkmethode: `WERKWIJZE.md`.
Launcher: `template-scripts/game-launchers/LINUXLAUNCHERS/ori-blindforest.sh` (v1).
Game: CODEX-repack `WINDOWSGAMES/Ori_atbf`. Prefix: verse `~/GAMEPREFIXES/OriBlindForest/`
(`.provisioned=1`). Steam-appid 261570.

## Game-analyse

- **CODEX-emu**: `codex.ini` → appid 261570; `steam_api.dll`/`.cdx` + `dinput8.dll` als
  loader-proxy in de gamemap → de game draait **standalone**.
- **32-bit PE32** `ori.exe` (Unity 5, Mono in `ori_Data/Mono`). Renderer DirectX 11.
- De aanwezige `ori_d3d11.log` toont `Exclusive FS: 1` → **gamescope-wrap nodig**.
- Saves: `AppData\Roaming\Steam\CODEX\261570\remote` (prefix-lokaal).

## Symptoom

Eerste run hing: "hang na ~5s, Primary child shut down". Een referentierun (2026-09-20)
**herhaalde dat niet**: `ori.exe` draaide >2 min stabiel, titel/menu zichtbaar en stabiel
(bevestigd door gebruiker). De eerdere hang is dus **niet gereproduceerd**.

## Oorzaak

Diffuus/perifeer; **niet** de pad. Mogelijk gelegen vóór de `PROTON_PIN`-pinning (Proton-
selectie was toen nog onbepaald). Geen reproduceerbare crash om af te trekken.

## Fix

Dunne launcher `ori-blindforest.sh`:

```bash
export SCRIPT_VERSION="1"
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="261570"
export PROVISION_HOOKS=(install_gamescope)
export GAME_GAMESCOPE="1"
```

- **gamescope-wrap** (Wayland) — zie `Exclusive FS: 1`-bewijs.
- **Resolutie auto** (`GAME_GAMESCOPE_RES` niet gezet → xrandr auto-detect; pin optioneel).

## Input (belangrijk)

- Default **`Enable SDL=0`** (drift-guard `disable_winebus`) is hier **extra belangrijk**:
  BF leest ook **DirectInput** en gaat "gek doen" (**"constantly moving left"**) zodra
  winebus een joystick ziet (bv. de Wacom-js).
- Dus **geen padmodus via SDL** voor BF. Een echte XInput-pad heeft de **root-route** nodig
  (`pad-xinput-on.sh`) — zie `BEVINDINGEN-GamepadTools.md`.

## Verificatie

- Referentierun: titel/menu stabiel; hang niet gereproduceerd.
- **Speeltest door gebruiker resteert** → daarna status "afgerond".

## Wat níét de oorzaak bleek

- **De gamepad/pad** — geen verband met de hang.
- Een reproduceerbare crash — die is er niet (meer).

## Terugdraaien

- `GAME_GAMESCOPE="1"` weghalen → geen wrap.
- Prefix opnieuw: `rm -rf ~/GAMEPREFIXES/OriBlindForest`.
