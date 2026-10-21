# Bevindingen: Sid Meier's Civilization VI (native Linux / Aspyr)

Datum: 2026-10-20
Analist: Diagnostiek-Agent
Locatie: `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Sid.Meiers.Civilization.VI/`
Startcommando: `Civ6`

## Samenvatting

**Er is geen probleem gevonden.** De native Linux-build van Civilization VI
(Aspyr, versie 1.0.0 build 56 / changelist 145503) start volledig en gezond.
De logs van vandaag (2026-10-20, 19:27–19:30) tonen een volledige, succesvolle
initialisatie en er is daadwerkelijk gameplay geweest (er is een auto-save
geschreven). Er is **geen crash, geen page fault en geen fatale fout**.

Dit is een **native** game: geen Wine-prefix, geen `WINEPREFIX`, geen `.reg`.
De WERKWIJZE.md (prefix-differentiatie) is hier dus **niet van toepassing**.
De diagnostiek is daarom uitgevoerd op de applicatie-logs van het spel zelf.

## Bewijs

### Binary en dependencies (OK)
- `Civ6`: ELF 64-bit LSB executable, x86-64, dynamisch gelinkt, gestript.
- `ldd Civ6`: **alle** libraries lossen op — zowel de meegeleverde
  (`libASL_Interpose.so`, `libGameCore_Base.so`, `libssl.so.1.0.0`,
  `libiconv.so.2`, `libcrypto.so.1.0.0`, `libcxxrt.so`, `libc++.so.1`,
  `libtbb.so.2`, `libsteam_api.so`) als de systeem-libraries. Geen "not found".

### Logs (OK — geen crash)
Pad: `~/.local/share/aspyr-media/Sid Meier's Civilization VI/Logs/`
- `Startup.log`: volledige reeks `InitialInit` → `GUIInit` met als laatste regel
  `Civ6App::GUIInit end.` (19:27:56). Alles draait: graphics, art manager, UI,
  input, scripting, modding, tuner, audio, Granny, binary serialization.
- `GameCore.log`: spel-logica draait normaal (random leaders, city states resolved).
- `FiraxisLive.log`: succesvolle login (`SSO_SUCCESS(0)`, `LoggedIn`).
- `Engine.log`: alleen `Bug collection enabled` — geen fouten.
- `ArtDef.log`, `Modding.log`, `UserInterface.log`: laatste writes 19:30:01–19:30:02.
- Auto-save aanwezig: `Saves/Single/auto/AutoSave_0001.Civ6Save` (19:29, 251 KB).
  Bewijst dat de game tot in-gameplay is gekomen, niet enkel het menu.

### GPU (OK)
- `glxinfo -B`: AMD Radeon RX 7600 XT (radeonsi, navi33), OpenGL 4.6,
  `Accelerated: yes`, 16 GB VRAM. Hardware-rendering werkt.
- `vulkaninfo`: Vulkan 1.4.357 aanwezig.

## Niet-fataal maar opvallend (geen actie nodig)

1. **`Startup.log` regel 4–6:**
   ```
   Running DoGraphicsDeviceSelection() ...
   Graphics device with ID: 0 not found.  Defaulting to device index: 0.
   Selected graphics device is: Unknown device.  Device ID: 29824.  Index: 0
   ```
   De game kan de GPU-naam niet enumereren zoals op Windows (DXGI). Dit is
   **cosmetisch** voor een native Linux-build; de daadwerkelijke rendering
   verloopt via de werkende AMD/Mesa-driver. Geen oorzaak van problemen.

2. **`Database.log`:**
   ```
   ERROR: table Colors already exists
   ERROR: table DiplomacyStatements already exists
   ERROR: table LeaderAnimations already exists
   ```
   Bekend, onschuldig Civ6-symptoom (dubbele mod-/DB-merge bij opstart).
   Komt op vrijwel elke Civ6-installatie voor en blokkeert niets.

3. **`Startup.log` tijdgat 19:27:22 → 19:27:56 (34 s):**
   tussen `Granny::Initialize()`/`SetupBinarySerialization()` en `GUIInit end`.
   Normaal: het asset-/shader-voorbereiden van de eerste start na een verse
   cache kan tientallen seconden duren.

4. **`Library`/verschil in rechten:** `libcrypto.so.1.0.0` en `libssl.so.1.0.0`
   hebben tijdstempel `Oct 20 19:26` (vandaag) terwijl de rest `Jan 1 2017` is.
   Deze twee zijn recent vervangen/gepatcht (oudere OpenSSL 1.0.0-API die de
   game verwacht). Ze lossen correct op; geen mismatch gedetecteerd.

## Conclusie

- Civ6 native start en werkt. **Geen fix nodig.**
- WERKWIJZE.md (Wine-prefix differentiatie) is niet van toepassing op deze
  native game — geen prefix, geen register.
- Mocht er in de toekomst tóch een crash optreden: leg dan het **fault-adres**
  en het stderr-/`dmesg`-spoor vast (WERKWIJZE.md valkuil 2) en vergelijk dat,
  in plaats van alleen "er was een crash".

## Terugrolmogelijkheid

Niet van toepassing — er is niets gewijzigd.
