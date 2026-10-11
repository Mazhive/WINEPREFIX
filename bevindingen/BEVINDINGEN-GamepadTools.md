# BEVINDINGEN — Gamepad-tools (pad-routes)

Werkmethode: `WERKWIJZE.md`. Tools in `template-scripts/tools/`.
Pad in kwestie: **`045e:028e` "Microsoft X-Box 360 pad"**.

> **Waarschuwing (staleness).** Delen van de documentatie lopen achter op de scripts:
> - `game-core/hooks/disable_winebus.sh` (regel ~21) verwijst nog naar
>   `tools/cyberpunk_gamepad.sh` — **dat bestand bestaat niet meer** (zie onder).
> - `READMEagents.md` (~r350, r421-430) en `GuideLineLauncher.md` (~r434, ~r510) noemen nog
>   `tools/cyberpunk_gamepad.sh` en vermelden `gamepad-status.sh` / `GAME_GAMEPAD` **niet**.
> - `READMEagents.md` noemt gearchiveerde bestanden onder `backup/` die daar feitelijk
>   **niet** staan (de `cyberpunk_gamepad.sh`-versie zit alleen in de Trash).

## Symptoom / probleem

De pad **werkt volledig op OS-niveau** (A/B/X/Y, LB/RB, L3/R3, Select/Start, beide sticks
vol bereik, triggers, D-pad — bewezen via evdev). Maar in **XInput-only games** (Cyberpunk,
Ori) is er **geen werkende route**.

## Analyse van de twee routes (bewezen)

### XInput/hidraw-route — dood

- De pad heeft **géén hidraw-node**: de kernel-**xpad**-driver claimt het USB-interface.
- `/dev/hidraw*` is `0600` root → winebus: `Unable to open "/dev/hidraw0", Permission denied`.
- Zonder leesbare hidraw bouwt Wine **geen XInput-controller** → Cyberpunk (XInput-only)
  ziet geen gamepad.

### SDL/evdev-joystick-route — faalt

- Met `Enable SDL=1` breekt het **toetsenbord in élke variant** (met/zonder
  `SDL_GAMECONTROLLER_IGNORE_DEVICES`, `EXCEPT`, `BLACKLIST` — getest in runs X/Y/Z).
- De pad krijgt **nog steeds geen device** (`evdev event3: deferring ... to a different
  backend`, waarna niets wordt aangemaakt).
- `SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT` zet de pad nota bene **zélf** op de
  negeren-lijst (verkeerde SDL2-semantiek).

### Nieuwe vondst (2026-09)

Een **schone SDL-context** (géén SDL-hint-env) laadt de pad **wél** als winebus-device met
`is_gamepad 1` (bewezen in een 20s-winebus-probe):

```
bus_create_hid_device desc {vid 045e, pid 028e, is_gamepad 1, ...}
```

De eerder gebruikte SDL-hints waren **zélf het gif** (de EXCEPT-variant zette de pad óp de
negeren-lijst). Gevolg: **gamepad-modus is zonder root mogelijk — ten koste van het
toetsenbord** (de game schakelt naar controllermodus; keyboard valt uit).

## Huidige staat van de tools

### SDL/winebus-route: opgegeven + gearchiveerd

- `tools/cyberpunk_gamepad.sh` (`status|probe|on|off`) bestaat **niet meer** — alleen nog in
  de Trash. Restant: `tools/archive/gamepad.off.sh.sdl-sweep.20260920`.
- Het eigen probe-verdict ("pad krijgt GEEN winebus-device") bewees dat de route doodloopt,
  én XInput-only-titels lezen sowieso alleen een wine-gebouwde XInput-controller.

### Vervanging: root-route als bewust los paar

Worden bewust **NIET** door launchers aangeroepen; los draaien (of later via GUI).

- **`tools/pad-xinput-on.sh`** — Xbox-pad als échte XInput-controller.
  - Default = **stabiel** via udev-rule `/etc/udev/rules.d/70-pad-xinput.rules`
    (`MODE="0660", GROUP="input", TAG+="uaccess"`).
  - `--shot` = proef-run: alleen tijdelijke `chmod 666` op de node (vervalt bij replug/reboot).
  - `status` = lees-only overzicht op OS-niveau.
  - Werking: xpad-driver uit (`modprobe -r xpad`) → usbhid/udev → hidraw leesbaar.
  - Zelf-gating: draait zichzelf als root via `sudo`/`pkexec`.
  - **Vereist** dat de gebruiker in de **`input`-groep** zit (anders blijft de node
    root-only; opnieuw inloggen na `usermod -aG input $USER`).
- **`tools/pad-xinput-off.sh`** — maakt de activering geheel ongedaan:
  udev-rule weg + `modprobe xpad` terug; **idempotent**; ook `status`.
  - Doet **géén** SDL/marker-schoonmaak — dat blijft bij de launch-time guard
    `disable_winebus` (SDL=0).
- **`tools/gamepad-status.sh`** — **read-only**, géén root. Rapporteert beide routes:
  - SDL/evdev-route (werkt zónder root; joystick zichtbaar voor SDL/DInput-games, bv. Crysis)
    — voeding via de ACL-lease van logind (`uaccess`) op `js*`/`event*`.
  - XInput-route (wine bouwt échte Xbox-controller uit hidraw; nodig voor XInput-only games).
  - Exit-codes: `0` = XInput-route klaar · `1` = pad niet aangesloten · `2` = pad
    aangesloten maar (nog) geen XInput-route.

### Launch-time toggle (geen root)

In `game-core/game-common.sh` (regels ~918-974): `GAME_GAMEPAD=1` (GUI-override
`GUI_GAMEPAD` heeft voorrang) zet per launch de **SDL/evdev-route** aan:

- `gamepad_begin()` → `.pad-mode`-marker in de prefix-root + `Enable SDL=1`.
- `gamepad_end()` → marker (alleen als wij 'm maakten) weg + `Enable SDL=0`.
- Geen root nodig (eigen prefix-registry + marker). `disable_winebus` slaat over zolang de
  marker ligt.
- **XInput-only games** (Ori, Cyberpunk) zien de pad via deze route **niet**; daarvoor
  blijven de root-tools `pad-xinput-on/off.sh` nodig.
- Als een joystickbewuste game naar controllermodus schakelt, kan het **toetsenbord
  uitvallen** (bewezen gedrag) → daarom een bewuste toggle.

### GUI

`game-gui.py`: checkbox **"Gamepad-modus (SDL / non-standaard)"** → `GUI_GAMEPAD=1`; bij
aanvinken draait de GUI ook `gamepad-status.sh` (read-only output) zodat de gebruiker de
routestaat ziet.

## Verificatie / bewijs

- OS-niveau: pad volledig werkend via evdev.
- winebus-probe: `is_gamepad 1` bij schone SDL-context.
- XInput-route: pas leesbaar na udev-rule + `input`-groep.

## Wat níét de oorzaak bleek

- **SDL-hints** (`SDL_GAMECONTROLLER_IGNORE_DEVICES`/`EXCEPT`/`BLACKLIST`) — hielpen niet en
  waren deels zélf het probleem.
- **`tools/cyberpunk_gamepad.sh`** — de SDL/marker-route; doodlopend bewezen en verwijderd.
- **Pad op OS-niveau** — werkte altijd al.

## Terugdraaien

- Root-route: `sudo tools/pad-xinput-off.sh` (udev-rule weg + xpad terug).
- SDL-toggle: `GAME_GAMEPAD`/GUI-checkbox uitzetten (auto-`Enable SDL=0` na launch).
- Marker handmatig: verwijder `.pad-mode` in de prefix-root (`${PREFIX_PATH%/pfx}/.pad-mode`).

## Zie ook

- `BEVINDINGEN-Cyberpunk2077.md` — gamepad in Cyberpunk (XInput-only).
- `BEVINDINGEN-OriWillOfTheWisps.md`, `BEVINDINGEN-OriBlindForest.md` — pad in Ori-titels.
