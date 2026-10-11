# BEVINDINGEN — Ori and the Will of the Wisps (WOTW)

Werkmethode: `WERKWIJZE.md`.
Launcher: `template-scripts/game-launchers/LINUXLAUNCHERS/ori-willofthewisps.sh` (v1, dun).
Prefix: verse `~/GAMEPREFIXES/OriWillOfTheWisps/` (`.provisioned=1`). Steam-appid 1057090.

## Game-analyse

- De repack-map `WINDOWSGAMES/Ori_atwotw` bevat **twee builds**: een UWP/GDK-rommel
  (`appxmanifest`, `launch-grdk.bat`, wdapp-register — alleen op echte Windows) en de
  **standalone PC-build** `oriandthewillofthewisps-pc.exe` + `..._Data`.
- Wij starten uitsluitend de **PC-build** (verifieerbare DXVK-run op GT 710).
- Unity **IL2CPP** (`GameAssembly.dll`) → geen Mono-laag; géén `steam_api`/emu-dlls in de
  boom → de repack draait **standalone**.
- Saves: `AppData\LocalLow\Moon Studios GmbH\...`.

## Symptoom/Oorzaak

Geen crash. De referentie-prefix `movedprefixes/1057090.ori_atwotw` gebruikte winetricks
`d3dx9/10/11_43` + `dxvk` + `vcrun6`, maar **onder modern Proton (GE-Proton11-7) is dat
niet nodig** — Proton levert die lagen zelf.

## Fix

Dunne launcher `ori-willofthewisps.sh`:

```bash
export SCRIPT_VERSION="1"
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="1057090"
export PROVISION_HOOKS=(install_gamescope)
export GAME_GAMESCOPE="1"
```

- **gamescope-wrap** omdat de DXVK-logs in de gamemap `Exclusive FS: 1` tonen (zelfde
  XWayland + AMD/RADV-presentatiepatroon als Cities: Skylines).
- **Resolutie auto**: `GAME_GAMESCOPE_RES` niet gezet → core auto-detect via xrandr
  (op deze machine 1080p/240Hz aangemaakt). Pin optioneel met `"WxH"`.
- Hook-wijzigingen triggeren géén re-provision (marker vergelijkt alleen `SCRIPT_VERSION`).

## Verificatie

- Boot → menu vlot; idle ~5%; gebruiker: "ging smooth".
- Reference-deps (`d3dx9/10/11_43`, `dxvk`, `vcrun6`) **niet** nodig.

## Gamepad

Óri is rond de controller ontworpen, maar **KBM is volwaardig/aanbevolen**.

- WOTW is **XInput-only** en schakelt naar **controllermodus** zodra een XInput-pad
  aanwezig is → toetsenbord wordt dan ondergeschikt.
- Pad-in-game = **root-route** (xpad weg + udev-hidraw / hidraw leesbaar) of **SteamInput**.
- **SDL-only levert bij WOTW niets.**
- Zie `BEVINDINGEN-GamepadTools.md` voor de huidige routestaat.

## Wat níét nodig bleek

- De referentie-winetricks (`d3dx9/10/11_43`, `dxvk`, `vcrun6`) onder modern Proton.
- SDL/evdev-route voor de pad.

## Zie ook

- `BEVINDINGEN-SteamTools.md` — `steam_appid.txt` (1057090) geneutraliseerd.
- `BEVINDINGEN-GamepadTools.md` — pad-routes.

## Terugdraaien

- `GAME_GAMESCOPE="1"` weghalen → geen wrap.
- Prefix opnieuw: `rm -rf ~/GAMEPREFIXES/OriWillOfTheWisps`.
