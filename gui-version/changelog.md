# Changelog voor game-gui.py


## game-gui-fork v0.2.6 (2026-10-20)

- **Iconen-boomstructuur gekoppeld aan fork**: `EMU-ICONS/` (geneste boom, spiegelt `GAMES/GAMES/`) + `_index.json` is nu de bron van waarheid voor emu-icons.
- `ensure_icon_structure()`: ontbrekende mappen (`systems/`, `emu-gameicons/`, `EMU-ICONS/`, `LINUXLAUNCHERS/`, `EMU-LAUNCHERS/`) worden bij elke opstart automatisch aangemaakt.
- `_scrape_icon_index()`: leest `EMU-ICONS/_index.json` (gegenereerd door `scrape_icons/`) en bouwt `by_path` (rom_path → icon) en `by_system` (system_key → icon).
- `EmuGame._resolve_icon()`: matcht eerst op `rom_path` via index, dan op `system_key`, dan fallback naar platte `emu-gameicons/`.
- `NavNode._resolve_icon()`: gebruikt ook `by_system` uit de scrape-index voor systeem-navnodes.
- `validate_icon_structure()`: controleert nu ook op `EMU-ICONS/_index.json`.
- `scrape_icons/placer.py`: schrijft de index nu ook naar `EMU-ICONS/_index.json` (naast `scrape_icons/games_index.json`), zodat de boom zelfbeschrijvend is en `scrape_icons/` later overbodig is.
- `README-game-gui-fork.md` §8: volledige documentatie van de iconen-boom, match-logica, `_index.json`, en icon pack concept.
- Versie: `0.2.5` → `0.2.6`.

## game-gui-fork v0.2.5 (2026-10-19)

- Nieuwe tool `template-scripts/tools/setup_icons.py`: valideert en creëert de vereiste icon-mapstructuur
  (`gameicons/` (root), `systems/`, `emu-gameicons/`, `LINUXLAUNCHERS/`, `EMU-LAUNCHERS/`).
- Standaard icon-map verplaatst naar `/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/` (platte structuur).
- Gebruiker kan icon-map selecteren via GUI (opslaan in `~/.config/gamelauncher/settings.conf`).
- Controleert kritieke bestanden: `back.jpg`, 28+ systeem-iconen, emu-covers.
- Interactieve modus met bevestiging, `--yes`/`--dry-run`/`--check-only` flags voor automatisering.
- Optie `--populate-systems` om ontbrekende systeem-iconen te kopiëren vanuit `PICTURES/ICONS/GAMEICONS/systems/`.
- `--verify` flag test de `_resolve_icon()` logica van NavNode/Game/EmuGame tegen daadwerkelijke bestanden.
- Zorgt dat scroller-iconen correct worden opgelost (systems/ eerst, dan root).

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

## v1.9.9 (2026-10-19)

- Nieuwe tool `template-scripts/tools/setup_icons.py`: valideert en creëert de vereiste icon-mapstructuur
  (`gameicons/` (root), `systems/`, `emu-gameicons/`, `LINUXLAUNCHERS/`, `EMU-LAUNCHERS/`).
- Standaard icon-map verplaatst naar `/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/` (platte structuur).
- Gebruiker kan icon-map selecteren via GUI (opslaan in `~/.config/gamelauncher/settings.conf`).
- Controleert kritieke bestanden: `back.jpg`, 28+ systeem-iconen, emu-covers.
- Interactieve modus met bevestiging, `--yes`/`--dry-run`/`--check-only` flags voor automatisering.
- Optie `--populate-systems` om ontbrekende systeem-iconen te kopiëren vanuit `PICTURES/ICONS/GAMEICONS/systems/`.
- `--verify` flag test de `_resolve_icon()` logica van Game/LauncherNode tegen daadwerkelijke bestanden.
- Zorgt dat scroller-iconen correct worden opgelost (systems/ eerst, dan root).

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
