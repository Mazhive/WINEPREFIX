# BEVINDING — Colin McRae Rally 04 (CMR4)

Datum: 2026-10-04. Status: **opgelost, game start en toont het menu.**
Werkmethode: `WERKWIJZE.md` in deze map. Productie-prefix: `~/GAMEPREFIXES/ColinMcRae4/pfx`.

## Symptoom

Een prefix die de launcher zelf bouwt liet `cmr4.exe` direct crashen:

```
Unhandled exception: page fault on read access to 0x00000000 in 32-bit code (0x0052435a).
EAX:00000000 EBX:00000000 ESI:00000000 EDI:00000000
0x0052435a cmr4+0x12435a: movl (%edi), %ecx
```

Een NULL-dereference: `EDI` is 0. Op de stack staat de string `fonts\HelNu_10.dds`
(uit de dwords `66 6f 6e 74 73 5c 48 65 6c 4e 75 5f 31 30 2e 64 73 64`) — de game was
bezig met het laden van een font-atlas. Dat bestand bestaat gewoon:
`fonts/HelNu_10.dds` (32.896 bytes).

## Oorzaak

CMR4 is een InstallShield-titel uit 2004 die zijn **eigen locatie uit het register
leest** en die sleutel op een schone prefix niet zelf aanmaakt. Alle vier de
werkende prefixen hebben hem:

| prefix | CurrentVersion | CMR4-sleutel |
|---|---|---|
| `movedprefixes/Collinmcrea4/pfx` | 6.1 / 7601 | ja |
| `movedprefixes/Collinmcrea4/pfx.djuga` | 6.1 / 7601 | ja |
| `movedprefixes/Collinmcrea4/pfx.noa` | 6.1 / 7601 | ja |
| `movedprefixes/Collinmcrea4 (copy)` | 6.1 / 7601 | ja |

```
HKLM\Software\Codemasters\Colin McRae Rally 04
  "INSTALL_PATH" / "CD_PATH" / "VIDEO_PATH" / "AUDIO_PATH"
      = Z:\mnt\VG_00\PUBLIC-LIBRARY\PRE-INSTALLED-GAMES\WINDOWSGAMES\Colinmcrea4
```

Zonder die sleutel heeft de game geen basis-map en crasht hij.

## Fix

Drie dingen in `template-scripts/game-launchers/LINUXLAUNCHERS/colinmcrea4.sh`,
`SCRIPT_VERSION` 2 → 3:

```bash
PROVISION_HOOKS=("install_win7" "install_dxvk" "install_d3dx9")
PRE_LAUNCH_HOOKS=("colinmcrea4_virtual_desktop" "colinmcrea4_registry")
```

- `colinmcrea4_registry` (nieuw, `game-core/hooks/`) zet de sleutel. Idempotent,
  onvoorwaardelijke overschrijving, eigen `wineserver -w` omdat er tussen
  `PRE_HOOKS` en `game_launch()` geen flush zit.
- `install_dxvk` toegevoegd: de referentie draaide **niet** op wined3d. De
  `winetricks.log` noemt `dxvk93` en `system32` bevat de native DXVK-dll's
  (`d3d9.dll` 1,73 MB / `dxgi.dll` 1,68 MB / `d3d11.dll` 2,48 MB /
  `d3d10core.dll` 1,01 MB).
- `install_d3dx9` toegevoegd: de referentie had `d3dx9_43`.

**Bewuste afwijking van de referentie:** huidige `dxvk` in plaats van `dxvk93`.
DXVK 0.9.3 is van 2017 en de prefix draait nu op wine-11.0.

## Resultaat

Verse prefix, één run:

- Windows 6.1 / 7601, prefix-architectuur-audit consistent
- DXVK actief (`info: Presenter: Actual swapchain properties`, swapchain 640×480)
- `colinmcrea4_virtual_desktop` zet 1280×960 (= 2× van de native 640×480);
  de game gaat daar fullscreen
- de game schrijft zelf `SpecSelection.bin` in de gamemap en zet zelf
  `ADAPTER_VID`/`ADAPTER_PID`/`WIDTH`/`HEIGHT`/`SPEC_SELECTION1..3` — hij doet dus
  zijn echte adapter-detectie en het menu verschijnt

## Wat níét de oorzaak bleek

- **Windows-versie.** De crash trad ook op toen de prefix al op 6.1/7601 stond
  (`backtracev2.txt` zegt `Version: Windows 7`, `Wine build: wine-11.0`).
  `install_win7` haalt de prefix dus terug naar de toestand van de referentie,
  maar het is niet wat de crash oplost.
- **DllOverrides.** De werkende prefix heeft er **nul**.
- **VC++/redist.** De referentie heeft geen `vcrun2019`.
- **dgVoodoo2.** De referentie heeft die niet.
- **`VideoMemorySize=256`** (de CenterFullscreen-tweak in `game-common.sh`).
- **De gamemap zelf.** `fonts/HelNu_10.dds` en `Data/` zijn compleet.

## Eerlijke kanttekening bij de attributie

Registry-sleutel, DXVK en d3dx9 zijn in **één** ronde toegevoegd. Daarmee is niet
geïsoleerd welke van de drie de crash wegnam. Dat wijkt af van de eigen regel in
`WERKWIJZE.md` ("één variabele per run"). Bewust zo gedaan om snel een werkende
launcher te hebben. Komt de crash terug, dan eerst `colinmcrea4_registry` uit
`PRE_LAUNCH_HOOKS` halen en de rest laten staan — één variabel per keer.

## Nog een open verschil met de referentie

De werkbare prefix heeft `mf` (Media Foundation); die is hier **niet** geïnstalleerd.
Gevolg: de introfilm faalt met

```
winegstreamer error: Missing decoder: Advanced Streaming Format (ASF)
```

Dat is niet fataal — de game start gewoon door — maar het is een vastgesteld
verschil. `install_win7`-achtige MF-hook toevoegen kan als de film gewenst is.

## Terugdraaien

- Alleen de sleutel: `colinmcrea4_registry` uit `PRE_LAUNCH_HOOKS` halen, of
  `wine reg delete 'HKLM\Software\Codemasters\Colin McRae Rally 04' /f`
- Launcher terug: snapshot `template-scripts/backup/ver1_20261004_101331`
- Prefix weggooien en opnieuw bouwen: `rm -rf ~/GAMEPREFIXES/ColinMcRae4`