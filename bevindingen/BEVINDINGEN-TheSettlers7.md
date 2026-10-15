# BEVINDINGEN — The Settlers 7: Paths to a Kingdom

> **STATUS 2026-10-11 (avond): CRASH GEVONDEN — geen externe blocker (meer).**
> De premisse is getest: de game start, logt in (`Logged in as: Pirate`, via de
> `1911.dll`-crack) en **crasht tijdens het laden van de menu-map**
> `Maps/Menu/Castle_Forge_Map` met een **NULL-dereference**.
> De Orbit/Uplay-vraag (oude oorzaak A) is daarmee voor offline gebruik
> **geneutraliseerd**. Wat overblijft zijn twee te differentiëren variabelen:
> **renderer (wined3d/OpenGL vs DXVK)** en **VC++ 2008 runtime (builtin vs native)**.

Diagnostiek-Agent, read-only analyse. Datum: 2026-10-11.
Methode: aftrekkende werkwijze uit `WERKWIJZE.md`. Er is **niets** gewijzigd aan
game-bestanden, prefixen of scripts; alleen gelezen.
> Update 2026-10-11 (avond): eerste premisse-run geanalyseerd. De prefix bestaat nu
> en er zijn echte logs/minidump. Alle wijzigingen hieronder zijn **metingen**, geen fixes.

---

## 0. Opdracht & inputs

| Rol | Pad |
|---|---|
| Game (root) | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/The.Settlers7` |
| Bootstrapper | `The.Settlers7/The_Settlers7.exe` (Ubisoft GameLauncher) |
| Echte game-exe | `The.Settlers7/Data/Base/_Dbg/Bin/Release/Settlers7R.exe` |
| Referentie-prefix | **bestaat niet** (geen match in `movedprefixes/`) — meetlat is de DXVK-log in de game-map |
| Productie-prefix | **bestaat sinds 2026-10-11 21:16**: `~/GAMEPREFIXES/TheSettlers7/pfx` (`#arch=win32`, Windows **7**) |
| Launcher / bevindingen | geen `*settler*.sh`; dit analysebestand |

Game: **The Settlers 7 – Paths to a Kingdom**, Ubisoft/Blue Byte, 2010, versie **1.2.1221**
(uit `Logfiles`, `S7_Patch, 120421`). Engine: **Vision 9**, **D3D9**, 32-bit.

---

## 1. Samenvatting (TL;DR — bijgewerkt)

1. **GECONFIRMEERD — crash bij menu-map (hoog):** `Loading map: Maps/Menu/Castle_Forge_Map`,
   dan `OnFirstFrame`, `Loading screen counter: 295 of total 300`, dan
   **`Exception 0xc0000005 at 0x009a5d48`** (module `Settlers7R.exe`, base `0x00400000`
   ⇒ **offset +0x5A5D48**), **`Read from location 0x00000000`**, `EDI=00000000`.
   Dit is de **hoofdmenu-achtergrondmap** ⇒ de game is feitelijk direct bij de start onbruikbaar.
2. **Uplay/Orbit (oude oorzaak A) — GENEUTRALISEERD voor offline (hoog):** er is **geen**
   `ubiorbitapi_r2.dll`; `1911.dll` (crack) levert een fake Orbit-sessie
   (`MgOrbitdllGetFakeSession`, `MgOrbitdllGetSavegameList`, …). De log zegt
   **`Logged in as: Pirate`**. Er is dus **geen** Uplay-account nodig om tot de menu-map te komen.
3. **VC++ 2008 (oude oorzaak C) — NOG NIET OPGELOST (hoog dat het nog openstaat):**
   de geladen `MSVCP90.dll`/`msvcr90.dll` zijn **Wine builtins** (`"Wine builtin DLL"`,
   versie `0.0.0.0`). **`vcrun2008` is niet geïnstalleerd** (`winetricks.log` = `win7`).
4. **Renderer — VERDACHTE (middel):** de run gebruikte **wined3d/OpenGL**
   (`OPENGL32.dll` geladen), **geen DXVK**, **geen `DllOverrides`**. De host-GPU is een
   **AMD RX 7600 XT**, maar de game ziet `ATI Radeon HD 5600 (0x68d8)` — wined3d
   **misidentificeert de adapter**. De enige overgebleven goede run (2020) gebruikte **DXVK v1.7-8**.
5. **CWD is GEEN variabele:** de engine zet cwd zelf op `...\The.Settlers7\Data`
   (4 niveaus boven de exe). Launcher-cwd doet er niet toe.
6. **De game heeft eerder gedraaid:** `Data/Settlers7R_d3d9.log` (2020-12-26, **DXVK v1.7-8**,
   GTX 1070) toont een aangemaakt D3D9-device. Dat is de **meetlat**; de prefix van toen is verdwenen.

---

## 2. Architectuur & uitvoerbare bestanden

`file`-uitvoer:

```
The_Settlers7.exe              PE32 i386 (GUI)  150016 B   2010-04-22   Ubisoft GameLauncher (bootstrapper)
Data/Base/_Dbg/Bin/Release/
  Settlers7R.exe               PE32 i386 (GUI) 13192504 B  2010-03-31   de echte game
  UPlayBrowser.exe             PE32 i386                       in-game Uplay-browser
  vBase90.dll, Vision90.dll, VisionEnginePlugin.vPlugin       Vision-engine (Vision 9)
  D3DX9_42.dll                 (gebundeld)                     DirectX 9 helper
  binkw32.dll, mss32.dll, mssdsp.flt, mssmp3.asi              Bink video + Miles audio
  SpeedTreeRT.dll, Sound.dll, 1911.dll, S7BaseGDF.dll
  dbghelp.dll, atimgpud.dll, Microsoft.VC90.CRT.manifest      VC++ 2008 (9.0)
Data/Base/BBA/{Gfx,Sound,Videos1,Videos2,Maps,LngEN,Interface,Shr,Fonts}.bba   game-data (grote .bba-archieven)
Data/Settlers7R.exe.dxvk-cache / _d3d9.log                     runtime-artefacten van een eerdere run
```

Bootstrapper-pdb: `P:\S7\ClosingKit\Trunk\Source\Install\GameLauncher\Bin\Release\The Settlers7.pdb`
⇒ bevestigt dat `The_Settlers7.exe` de **installer/launcher**, niet de game is.

Start-keten (bevestigd t/m menu):

```
The_Settlers7.exe (GameLauncher)  --HTTP/update-->  S7GameUpdate.exe   (dode servers)
                                  --start-->        Settlers7R.exe
Settlers7R.exe  --1911.dll (crack)-->  fake Orbit/Uplay-sessie  => "Logged in as: Pirate"
                --laadt-->  Maps/Menu/Castle_Forge_Map  =>  CRASH (NULL-deref)
```

---

## 3. Import-evidentie

Uit `Settlers7R.exe` (imports + strings):

```
Imports  : MSVCP90.dll, MSVCR90.dll        -> VC++ 2008 (9.0) runtime
           WINHTTP.dll, WININET.dll, WS2_32.dll, IPHLPAPI.DLL
           d3dx9_42.dll, binkw32.dll, mss32.dll, SpeedTreeRT.dll
           vBase90.dll, Vision90.dll, CInput3DX.dll, GDI32, SHELL32, VERSION, WINMM
Dyn. load: ubiorbitapi_r2.dll              -> door de crack vervangen door 1911.dll
Netwerk  : Quazal: CUPlay, CUPlayQuazalImpl, UplayWinProtocolClient, UPlayRewardMgr
Auth     : UbiAuthenticationClient, UbiAccountManagementClient, ...
Cloudsave: orbitclient / orbitdll
Crack    : 1911.dll bevat MgOrbitdllGetFakeSession / GetLoginDetails / GetSavegameList ...
```

---

## 4. Log-inventaris & meetlat (bijgewerkt)

| Bestand | Datum | Inhoud |
|---|---|---|
| `~/Documents/Settlers7/Logfiles/Settlers7_AGame_2026-10-11_21-18-15.log` | 2026-10-11 21:18 | **Run 1**: tot `BootUp Network Engine`; **geen** crashregel (run gestopt/afgebroken) |
| `~/Documents/Settlers7/Logfiles/Settlers7_AGame_2026-10-11_21-21-41.log` | 2026-10-11 21:21 | **Run 2**: **CRASH** — zie §5 |
| `~/Documents/Settlers7/Minidumps/Settlers7_AGame_2026-10-11_21-22-37.dmp` | 2026-10-11 21:22 | minidump van run 2 (geen bijbehorende PDB) |
| `~/Documents/Settlers7/Replays/settlers7_..._21-22-25.rpl` | 21:22 | 0 bytes |
| `~/Documents/Settlers7/Options.ini` | 21:21 | `FullScreen=1`, `ScreenWidth=1024/Height=768`, low-effect profiel |
| `Data/Settlers7R_d3d9.log` | **2020-12-26** | DXVK v1.7-8; GTX 1070; **D3D9-device aangemaakt** (meetlat) |
| `Data/Settlers7R.dxvk-cache` | 2022-04-18 | DXVK state-cache (317 entries) |

Run 2 log (kern):

```
The current directory is "Z:\...\The.Settlers7\Data".
...
Logged in as: Pirate
Video mode forced to 1024x768 239hz
Graphics adapter detected:
    Vendor: 0x1002
    Device: ATI Radeon HD 5600 Series (0x68d8, rev.0)   <-- host is AMD RX 7600 XT (misID)
    Driver: 9.21.10.1280
Loading map: Maps/Menu/Castle_Forge_Map using template (none)
OnFirstFrame
Loading screen counter: 295 of total 300
Timestamp: 1878780923411708
[ 2026/10/11 21:22:37 ] ERROR: Exception 0xc0000005 at 0x009a5d48!
  ... access violation in module Settlers7R.exe ... at 0023:009a5d48
  Read from location 0x00000000 caused an access violation.
  Registers: EAX=3dda1380 ... EDI=00000000 ...
  CS:EIP: 009a5d48  8b 07 8b 35 98 54 e1 00 ...      (8B 07 = mov eax,[edi]  -> NULL-deref)
  Stack:   009a5d48, 009a72c0, 009ad353, 00b35f66    (return-adressen binnen Settlers7R.exe)
```

**Runtime-omgeving (statisch gecontroleerd in de prefix):**

| Check | Uitkomst |
|---|---|
| Prefix-arch | `#arch=win32` ✓ (juist voor PE32) |
| Windows-versie | Win **7** (`winetricks.log` = `win7`) |
| `msvcr90.dll` / `msvcp90.dll` | **Wine builtin** (`PE32 executable for WINE`, `"Wine builtin DLL"`, `0.0.0.0`) |
| `vcrun2008` | **niet geïnstalleerd** |
| `[Software\Wine\DllOverrides]` | **leeg** (geen native overrides) |
| `d3d9.dll` | Wine builtin (wined3d), **geen DXVK** |
| Host-GPU | AMD **RX 7600 XT** (Navi33), Mesa 26.2.3, RADV; DXVK 2.7.1/3.1.1 gecached |

---

## 5. Root-cause analyse (met vertrouwen)

**Primair symptoom (zeker):** NULL-pointer-deref in `Settlers7R.exe+0x5A5D48` tijdens
het laden/afronden van de menu-map, na `OnFirstFrame` en op `295/300` van het laadscherm.
De instructie is `mov eax,[edi]` met `EDI=0` ⇒ de engine leest een pointer die **NULL** is.

### A. Uplay/Orbit + UbiAccount-auth — **GENEUTRALISEERD (hoog, voor offline)**
Geen `ubiorbitapi_r2.dll`; `1911.dll` crackt de Orbit-sessie; log toont `Logged in as: Pirate`.
⇒ **Geen account nodig** om tot de menu-map te komen. Multiplayer/cloudsave blijven dood
(irrelevant voor singleplayer).

### B. Bootstrapper/auto-updater naar dode servers — **MIDDEL** (omzeilbaar)
Niet meer op het kritieke pad zolang **direct `Settlers7R.exe`** wordt gestart (de run deed dat).

### C. VC++ 2008 (9.0) runtime — **OPEN (middel-hoog)**
Import van `MSVCR90/MSVCP90` is **bewezen echt**, maar de geladen DLL's zijn **Wine builtins**.
De builtin-crt is grotendeels functioneel gebleken (profiles/archieven/netwerk init OK),
maar **map-loading** (STL/streams) is precies een plek waar een stub NULL kan teruggeven.
Fix: `install_vcrun2008` (native). **Nog niet getest.**

### D. Renderer wined3d/OpenGL — **VERDACHT (middel)**
Crash op **eerste frame / afronden map-load** (graphics-resource creatie), en de adapter
wordt **fout** geïdentificeerd (`0x68d8`). De enige bekende goede run gebruikte **DXVK**.
Fix: DXVK installeren. **Nog niet getest.**

**Niet differentieerbaar zonder run:** of de NULL uit **C** of **D** komt. Beide zijn
afzonderlijke variabelen (runtime vs. renderer) en moeten los getest worden (WERKWIJZE:
één variabele per run).

---

## 6. Wat NIET (bewezen) de oorzaak is

- **"Geen prefix"** — nu bestaat `~/GAMEPREFIXES/TheSettlers7/pfx` (win32, win7). Geen oorzaak.
- **CWD** — de engine zet cwd zelf op `...\Data`; niet stuurbaar via de launcher. Geen oorzaak.
- **De `_Dbg` in het pad** — cosmetisch (zo geleverd door Blue Byte); geen oorzaak.
- **D3DX9 ontbreekt** — onwaar: `d3dx9_42.dll` zit gebundeld in de Release-map.
- **Ontbrekende iconen** — onwaar: `Settlers7.png` (306 KB) staat in de game-root.
- **Uplay-login** — weerlegd: `Logged in as: Pirate` (crack).

---

## 7. Premisse-check — VERVULD

De vorige versie van dit document vroeg om een crash + fault-adres. Die zijn er nu:
- crash: `0xc0000005` op **`Settlers7R.exe+0x5A5D48`**, **read `0x00000000`** (EDI=0);
- context: menu-map `Castle_Forge_Map`, na `OnFirstFrame`, `295/300`.

Resterende open vraag is **niet** meer "is er een blocker", maar **welke van de twee
variabelen (C runtime / D renderer) de NULL-deref veroorzaakt**.

---

## 8. Actieplan voor de Launcher-Builder (HANDOFF — diag-agent schrijft géén .sh)

> Uitvoering hoort bij de **Launcher-Builder Agent**. Onderstaande is het plan; er is
> **niets** uitgevoerd of gewijzigd door de Diagnostiek-Agent.

### 8.1 Launcher-basis (conform boilerplate + GUI-header `_read_launcher_meta`)
- **`export GAME_NAME="TheSettlers7"`**
- **`export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/The.Settlers7"`**
- **`export GAME_EXE="$GAME_DIR/Data/Base/_Dbg/Bin/Release/Settlers7R.exe"`**
  (niet de bootstrapper `The_Settlers7.exe`)
- **`export PREFIX_ARCH="win32"`** ← **verplicht** (32-bit; wijkt af van de win64-templates)
- **`export GAME_ICON="TheSettlers7.png"`** en **`export GAME_DISPLAY_NAME="The Settlers 7"`**
- Desktop-shortcut aan; `SCRIPT_VERSION="1"`.

### 8.2 Differentiatie — **één variabele per run** (bewaar exact fault-adres)
Start **altijd direct `Settlers7R.exe`** met de bestaande verse prefix
(`~/GAMEPREFIXES/TheSettlers7/pfx`, win32/win7). Vergelijk na elke run het **fault-adres**
en of het verandert.

- **Run A (renderer):** `winetricks -q dxvk` in de prefix. Draai opnieuw.
  - Zelfde adres `+0x5A5D48`? ⇒ renderer is de oorzaak **niet**.
  - Ander/geen adres of spel komt verder? ⇒ renderer was op het pad.
- **Run B (runtime):** `winetricks -q vcrun2008` in de prefix. Draai opnieuw.
  - Controleer in de nieuwe log dat `MSVCP90/msvcr90` **niet** meer `0.0.0.0` zijn
    (native Microsoft-runtime). Zet zo nodig `WINEDLLOVERRIDES="msvcr90,msvcp90=n"`.
  - Zelfde adres? ⇒ runtime is de oorzaak **niet**.

**Aanbevolen volgorde:** **Run A (DXVK) eerst** — de crash zit op het eerste frame en de
enige bekende goede run (2020) gebruikte DXVK; daarna **Run B (vcrun2008)**. Voer **nooit**
A en B in één run samen (WERKWIJZE: één variabele per run).

### 8.3 Hooks (voorstel)
- **Wel:** `install_vcrun2008` — bewezen nodig (`MSVCR90/MSVCP90`-import) en nu nog open.
- **Geen** `install_vcrun2019+`: de import wijst op 9.0.
- **Orbit/Uplay:** **niet** aanraken — crack (1911.dll) levert de fake sessie al; account niet nodig.
- **Gamescope/winebus:** niet preventief; alleen bij concrete Wayland/fullscreen-/inputklachten.

### 8.4 Icoon (beleid `AGENTS.md`)
`The.Settlers7/Settlers7.png` (306 KB, 512+ px) → kopiëren/herschalen naar
`template-scripts/game-launchers/gameicons/TheSettlers7.png` (transparant).

### 8.5 Runner
Begin met **plain Wine** (32-bit prefix). Test DXVK als losse variabele (Run A); test Proton
pas daarna, los.

---

## 9. Aanbevolen testvolgorde (aftrekkend, één variabele per run)

1. **Baseline-run** (verkregen): verse win32-win7-prefix, direct `Settlers7R.exe`.
   Resultaat: login OK, crash `+0x5A5D48` bij menu-map. ✅ uitgevoerd, vastgelegd in §4.
2. **Run A — renderer:** DXVK erbij. Zelfde meting (fault-adres? komt spel verder?).
3. **Run B — runtime:** vcrun2008 erbij (los van A). Zelfde meting.
4. **Alleen bij aanhoudende crash ná A en B:** verder differentiëren — fullscreen vs windowed
   (`Options.ini` `FullScreen=1`), daarna DllOverrides/Graphics-driver. Gebruik de
   **leave-one-in**-variant (WERKWIJZE valkuil #3).
5. **Leg vast** vóór `movedprefixes/` verdwijnt (meetlat = de DXVK-log in de game-map, die blijft).

---

## 10. Randvoorwaarden / overdracht

- **Diagnostiek-Agent (read-only):** heeft **niets** gewijzigd; alleen gelezen en dit
  analysebestand bijgewerkt. Eindigt hier.
- **Overdracht → Launcher-Builder Agent:** lees dit bestand en voer §8/§9 uit
  (launcher + de twee losse variabelen A/B). Schrijf meetresultaten terug.
- **Belangrijkste risico:** als **beide** variabelen (DXVK én native vcrun2008) het
  `+0x5A5D48`-adres niet veranderen, is er een diepere Vision-9/wined3d-incompatibiliteit
  of een crack-afhankelijk data-probleem; dan further bisecten (fullscreen, d3dx-override,
  shader/qualiteit in `Options.ini`) en anders documenteren als harde blocker.
</content>
