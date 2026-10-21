# BEVINDINGEN — Figment (Native Linux)

Werkmethode: `WERKWIJZE.md` (diagnose-protocol).
Locatie: `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Figment/`
Start: `start.sh` (GOG.com installer wrapper)
Binary: `game/Figment.x86_64` (ELF 64-bit, Unity-engine)

## Game-analyse

- **Platform:** Native Linux (x86_64), geen Wine/Proton.
- **Engine:** Unity (IL2CPP/Mono mix zichtbaar in logs; `Figment_Data/Managed/` bevat Unity assemblies).
- **Installatie:** GOG.com Linux build (`.sh` installer aanwezig in GAMES/LINUX: `figment_en_1_0_0_0_15133.sh`).
- **Startmethode:** `start.sh` sourced `support/gog_com.shlib`, `run_game()` gaat naar `game/` en voert `./Figment.x86_64` uit.
- **Versie:** gameinfo toont `Figment` / `1.0.0.0` / `15133` (en-US).

## Runtime-observaties

- **User-data / saves:** 
  - `~/.config/unity3d/Bedtime Digital Games/Figment/` (heeft o.a. `Player.log`, `prefs`, `Unity/Analytics/`)
  - `~/My Games/Figment/` (o.a. `Config.cfg`, `RoamingConfig.cfg`, `Saves/`)
- **Logs:** `~/.config/unity3d/Bedtime Digital Games/Figment/Player.log` toont normale Unity startup: device creatie, level loads, menu actief. Geen fatale crashes zichtbaar in de recente log.
- **Graphics:** Rapportage van desktop resolutie 1920x1080 @ 239Hz, fullscreen requests naar 1920x1080. Statische shader waarschuwingen ("Shader \"NULL\" on ColorCorrectionMultiLookup is not supported") zijn typisch Unity-noise.
- **Audio/UI:** Kleinere Unity-warnings (bv. "Failed to find UI camera", subtitle groep niet gevonden) zonder crash-impact.

## Diagnose

Geen directe crash of fatale fout geconstateerd op basis van beschikbare logs. De installatie is een standaard GOG Linux build; start via `start.sh` is correct.

Mogelijke aandachtspunten (preventief):
- Unity Linux builds kunnen gevoelig zijn voor GPU-drivers/mesa; shader-warnings zijn normaal.
- Configuratie leeft in Unity user dirs (`~/.config/unity3d/...`, `~/My Games/...`) — bij het debuggen eerst deze checken bij afwijkend gedrag.
- Analytics-map aanwezig onder Unity config.

## Conclusie

**Status:** Werkend ogend / geen reproduceerbare crash in huidige logs. Geen Wine-prefix nodig (native build). Startmethode correct conform GOG wrapper.

## Aanbevolen verificatie

```bash
cd /mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Figment
./start.sh
# of direct
cd game && ./Figment.x86_64
```

Bij daadwerkelijke crash: bewaar `~/.config/unity3d/Bedtime Digital Games/Figment/Player.log`, `Player-prev.log` (indien aanwezig), `core` dumps en terminal output van `start.sh`.
