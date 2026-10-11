# Changelog voor game-gui.py

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