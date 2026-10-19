# Changelog voor game-gui.py


## game-gui-fork v0.2.4 (2026-10-18)

- Preconf-mechanisme: standaard-config naast de AppImage (`<emu-dir>/preconf/`)
  wordt bij het starten automatisch in de user-config gezet (`cp -rn`, nooit
  overschrijven). Nieuwe conf-velden `userconf=` en `preconf=`.
- PCSX2-voorbeeld: preconf met PAL-BIOS + `PCSX2.ini`; `[ps2]` args
  `-nogui -fullscreen -fastboot %ROM%` → game start direct, geen menu.
- README-game-gui-fork.md §7: preconf gedocumenteerd.

## game-gui-fork v0.2.3 (2026-10-18)

- PS2-games als map (met daarin een `.iso`) werken nu: `emu-launch.sh` zoekt
  een rom-bestand in de map en gebruikt dat.
- Echte folder-dumps (met `SYSTEM.CNF`) worden met `xdvdfs pack` naar een
  gecachte iso (`~/.cache/gamelauncher/iso/`) gepackt en hergebruikt.
- GUI blokkeert mappen niet meer; `accept_dir=1`-emulators (RPCS3) krijgen de
  map nog steeds rechtstreeks.
- Bugfix: `%ROM%`-substitutie zonder `eval`, zodat paden met spaties/haakjes
  niet meer stukliepen (was: `printf '%q'` + `sed` + `eval`).
- README-game-gui-fork.md §4: subsectie "Mappen en iso's".

## game-gui-fork v0.2.2 (2026-10-18)

- Emulator installeren via de launcher: bij ontbrekende emulator (`status=missing`
  of `emu`-pad bestaat niet) vraagt de GUI "Nu installeren? (emu-install.sh)".
- `_install_emulator()` start `emu-install.sh` (env `GAME_SYSTEM` + `GAME_EMU_CONF`),
  streamt de output naar de terminal en herstart de game na succes.
- `reload_emulators()` wist de conf-/statuscaches en herdetecteert na een installatie.
- `emu-launch.sh` probeert bij een ontbrekende emulator `emu-install.sh` en herleest de conf.
- README-game-gui-fork.md §6: install-flow gedocumenteerd (was "uitgesteld").

## game-gui-fork v0.2.1 (2026-10-18)

- `emulation.conf` + `emulators.json` verhuisd naar `~/.config/gamelauncher/`
  (per PC); repo-versie blijft sjabloon/fallback. GUI geeft het pad door via
  `GAME_EMU_CONF`; `emu-launch.sh` leest de home-conf eerst.
- Emulator-detectie bij opstarten: alle systemen uit `emulation.conf` worden
  gecontroleerd (home- + repo-pad als kandidaten) → `emulators.json`.
- Melding in de terminal wanneer een systeem nog geen (gevonden) emulator heeft.
- README-game-gui-fork.md toegevoegd.

## game-gui-fork v0.2.0 (2026-10-18)

- Drill-down navigatie (NavNode/EmuGame), platform-scanning,
  launch-splitsing (`_start_pc`/`_start_emu`), navbar met terug-knop.

---

## v1.9.8 (2026-10-17)

- Robuuste Multi-Platform OS-detectie: 
- De OS-detectie (detect_os_name()) is geoptimaliseerd voor zowel Linux (via /etc/os-release) 
- als Windows-systemen (via platform.win32_ver(), inclusief automatische build-gebaseerde herkenning van Windows 11).   Code Opschoning: Volledig verwijderd van overbodige, verouderde hardcoded dictionaries (DISPLAY_NAMES en ICON_OVERRIDES). Game-titels en iconen 
- worden nu volledig dynamisch opgelost via script-metadata, _prettify() en fuzzy matching.


## v1.9.7 (2026-10-16)

- Integratie van de gedetecteerde systeem-/distributienaam 
- als subtitel onder de "WWN GAME LAUNCHER" header. 


## v1.9.6 (2026-10-16)

- Case-insensitive sortering voor launcher-lijst en soundtrack-bestanden 
- (fix: ThelastofusiiRM stond vooraan door hoofdletter T)



## v1.9.5 (2026-10-15)

- Knight Rider-scanlijn groen gemaakt (matcht terminal `#00ff88`)
- Uitdovende staart (trailing fade) achter de kop, tegengesteld aan de bewegingsrichting

## v1.9.4 (2026-10-15)

- Knight Rider-achtige scanlijn (`KnightRiderBar`) boven de terminal: gloeiende rode balk die heen en weer schuift zolang een game start/draait
- Scanner verschijnt bij start en verdwijnt zodra de run stopt; volgt de actieve run bij tabwissel/sluiten

## v1.9.3 (2026-10-11)

- Volume effect regel onder vkBasalt geplaatst, halve hoogte; checkbox "volume effect" links, slider ernaast (1 kollom)

## v1.9.2 (2026-10-11)

- vkBasalt-checkbox (vibrance/deband) toegevoegd, standaard uit, per-launch (niet gepersisteerd)
- `GUI_VKBASALT` doorgegeven aan de core; `_neutralize_overlays()` behandelt MangoHud en vkBasalt nu onafhankelijk

## v1.9.1 (2026-10-11)

- Alleen `_stop_soundtrack()` in callback, geen checkbox/settings wijziging (fix startup vertraging door synchrone disk write in `save_settings()`)

## v1.9.0 (2026-10-10)

- Soundtrack functionaliteit toegevoegd (cvlc loop, checkbox, volume slider)
- Wielmuis geluid (scroll.wav generatie)
- Gamepad-modus toggling
- MangoHud overlay checkbox
- Snapshot backup checkbox
