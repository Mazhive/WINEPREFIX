# BEVINDINGEN — wacom-detect (herbruikbare module)

Werkmethode: `WERKWIJZE.md`.
Module: `template-scripts/game-core/hooks/wacom-detect.sh`.
Status: **bewaard als herbruikbare interactieve module** — niet meer in de Cyberpunk-flow.

> **Waarschuwing (staleness).** Eerdere beschrijvingen noemden `_wacom_as_joystick` (vindt
> `js0`) en `_wacom_await_unplug` (`WACOM_WAIT_SEC`, standaard 30 s). Die functies bestaan
> **niet meer** in de huidige module. De module detecteert nu "valse" joysticks en biedt de
> bewezen `Enable SDL=0`-fix aan via een Ja/Nee-vraag (geen wachten op loskoppelen).

## Doel

Sommige games (o.a. Cyberpunk 2077) zien een willekeurig joystick-achtig apparaat als
gamecontroller en zetten dan muis+toetsenbord uit (bekende "Press SPACE"-deadinput).
Op deze machine zijn er twee zulke "valse" joysticks:

- een **Wacom-tablet** die via joydev als `/dev/input/js*` wordt geëxposeerd (VID `056a`);
- de eigen **USB-toetsenbord-js** (bv. Lenovo `17ef:6099`, `ID_INPUT_KEY=1`) die joydev
  óók als `js*` aanmeldt — **die is er altijd**, dus "Wacom-kabel los trekken" is nooit genoeg.

## Functies (huidige staat)

| Functie | Doet |
|---|---|
| `_wacom_present()` | Detecteert een aanwezige Wacom via `/dev/input/by-id/*wacom*` of `udevadm` op `event*` (match `wacom`/`056a`) |
| `_bogus_joysticks()` | Loopt `js*` af; meldt Wacom-js en toetsenbord-js (`ID_INPUT_KEY=1`/`17ef`/keyboard); laat een **echte** gamepad (`ID_INPUT_JOYSTICK=1`) met rust |
| `_apply_fix()` | De bewezen fix: winebus `Enable SDL=0` (hidraw blijft aan) + `wineserver -w` flush + controle |
| `hook_run()` | Detecteert, toont de vondst, vraagt Ja/Nee, en past de fix toe bij "Ja" |

## Bewezen fix

**Alleen** `Enable SDL=0` in
`HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\winebus\Enable SDL`:

- `DisableHidraw` wordt **niet** gezet (dat maakte voorheen óók alle echte gamepads onbruikbaar).
- Met deze instelling werken **toetsenbord én gamepad tegelijk**.
- SDL-env-hints (`SDL_GAMECONTROLLER_IGNORE_DEVICES` e.d.) worden door de game **niet**
  gehonoreerd (getest); de **registry-waarde wél**.

## Interactie

- Via `tools/ask-yesno.sh` (TTY → kdialog → zenity).
- Overslaan van de prompt / vooraf instellen met **`WACOM_CHOICE=ja|nee`** (GUI-ready).
- Fallback-`_log` zodat de module ook los (zonder `game-common.sh`) bruikbaar is.
- Oproep: `PRE_LAUNCH_HOOKS=("wacom-detect")` (bij élke start) of `PROVISION_HOOKS=("wacom-detect")`.
  De fix is idempotent → pre-launch is de juiste plek.

## Waarom niet (meer) in Cyberpunk

**Test D** bewees dat de **Wacom onschuldig** is: `Enable SDL=0` + Wacom erin → toetsenbord
en gamepad werken, óók bij keuze "Nee". Cyberpunk gebruikt nu de **stille** provision-hook
`disable_winebus` (alleen `Enable SDL=0`). Zie `BEVINDINGEN-Cyberpunk2077.md`.

## Terugdraaien

- Fix terug: `wine reg add ...\winebus /v "Enable SDL" /t REG_DWORD /d 1 /f`.
- Module niet oproepen: de hooknaam uit `PRE_LAUNCH_HOOKS`/`PROVISION_HOOKS` halen.

## Zie ook

- `BEVINDINGEN-Cyberpunk2077.md` — waar de fix vandaan komt.
- `BEVINDINGEN-GamepadTools.md` — pad-routes en de `SDL`-route.
