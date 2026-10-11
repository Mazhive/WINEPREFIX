# BEVINDINGEN — Cyberpunk 2077

Werkmethode: `WERKWIJZE.md`. Productie-prefix: `~/GAMEPREFIXES/Cyberpunk2077/pfx`.
Launcher: `template-scripts/game-launchers/LINUXLAUNCHERS/cyberpunk2077.sh` (v17).

## Symptoom

De game negeert het **toetsenbord** zodra er één joystick-achtig apparaat zichtbaar is.
Op de betrokken machine is er altijd minstens één: de eigen **Lenovo-toetsenbord-js**
(`17ef:6099`, `ID_INPUT_KEY`) plus willekeurige andere (Wacom `056a`).
Concreet: op het startscherm doet de spatiebalk niets (bekende "Press SPACE"-deadinput).

## Oorzaak (bewezen 2026-09)

Wine bouwt uit een joystick-achtig device een "controller", waarop de game naar
**controllermodus** schakelt en muis+toetsenbord ondergeschikt maakt.

- Isolatietest: Space dood met **alleen** de keyboard-js (js1) — géén Wacom, géén gamepad.
  "Wacom los trekken" kan dus nooit de volledige fix zijn.
- De klassieke remedy zette `Enable SDL=0` **én** `DisableHidraw=1`, maar `DisableHidraw`
  schakelde **alle** echte gamepads uit.

## Fix

**Winebus `Enable SDL=0`**, met hidraw intact (`DisableHidraw` wordt **niet** gezet):
dan herstelt het toetsenbord, terwijl echte gamepads via XInput/hidraw blijven werken.

- SDL-env-hints (`SDL_GAMECONTROLLER_IGNORE_DEVICES` en varianten) worden door de game
  **niet** gehonoreerd — getest, geen effect.
- **Test D (Wacom-onafhankelijkheid):** `Enable SDL=0` + Wacom erin (ook mét pad) →
  Space werkt, óók wanneer de keuze-dialoog met "Nee" wordt beantwoord. Conclusie: de
  wacom-detect-flow is voor Cyberpunk **overbodig**.

Implementatie (hook `game-core/hooks/disable_winebus.sh`):

- Zet **uitsluitend** `HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\winebus\Enable SDL=0`;
  hidraw blijft aan.
- Idempotent en snel → veilig als provision- én pre-launch-hook.
- Escape-hatch: als de padmodus-marker `.pad-mode` in de prefix-root ligt, slaat de hook
  over (zie `BEVINDINGEN-GamepadTools.md`).

Launcher v17:

```bash
export SCRIPT_VERSION="17"
export PROTON_PIN="GE-Proton11-7"
export PROVISION_HOOKS=("install_gamescope" "install_vcrun2019" "disable_winebus")
export PRE_LAUNCH_HOOKS=("disable_winebus")   # drift-guard bij élke start
export GAME_GAMESCOPE="1"
export VC_RUNTIME_METHOD="redist"
```

`PRE_LAUNCH_HOOKS=("disable_winebus")` is de **drift-guard**: `Enable SDL=0` staat bij élke
start gegarandeerd en blijft staan als de registry ooit weer wordt omgezet.

## Versie-historiek (beknopt)

| Versie | Kern |
|---|---|
| v13 | `disable_winebus`: `Enable SDL=0` + `DisableHidraw=1` (inputfix) + `install_gamescope`/Wayland-wrap |
| v14 | `disable_winebus` eruit — schakelde ook echte gamepads uit; vervangen door `wacom-detect` (vraagt Wacom los te koppelen) |
| v15 | `wacom-detect` via `tools/ask-yesno.sh` (TTY/kdialog/zenity; GUI-ready via `WACOM_CHOICE=ja\|nee`) |
| v16 | werkende v13-voorzieningen terug (vcrun2019, PROTON_PIN, gamescope) + wacom-detect behouden |
| v17 | oorzaak bewezen; `wacom-detect` uit de flow; fix = `Enable SDL=0` (hidraw aan), provision + pre-launch |

## v16-provision (live geslaagd)

- Backup-snapshot op de share
- Hooks draaiden; marker v16
- `.desktop`-shortcut aangemaakt
- gamescope-wrap actief (Wayland)
- Proton gestart

## Wat níét de oorzaak bleek

- **Wacom loskoppelen** — de keyboard-js blijft altijd bestaan (Space dood zonder Wacom).
- **SDL-env-hints** (`SDL_GAMECONTROLLER_IGNORE_DEVICES` e.d.) — geen effect.
- **`DisableHidraw`** — hielp voor het toetsenbord, maar sloopte echte gamepads.
- **Gamepad via SDL/evdev-route** — zie `BEVINDINGEN-GamepadTools.md`; voor Cyberpunk
  (XInput-only) sowieso dood.

## Terugdraaien

- Launcher terug: snapshot in `template-scripts/backup/`.
- Registry: `wine reg add ...\winebus /v "Enable SDL" /t REG_DWORD /d 1 /f` (zet de
  toestand terug naar SDL aan).
- Prefix opnieuw: `rm -rf ~/GAMEPREFIXES/Cyberpunk2077`.

## Zie ook

- `BEVINDINGEN-WacomDetect.md` — herbruikbare module `wacom-detect.sh` (niet meer in deze flow).
- `BEVINDINGEN-GamepadTools.md` — gamepad-routes (huidige staat).
