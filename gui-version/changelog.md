# Changelog voor game-gui.py


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
