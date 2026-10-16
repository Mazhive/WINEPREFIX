# BEVINDINGEN — The Last of Us Part II (Remastered)

Datum: 2026-10-16. Status: **oorzaak bewezen en gereproduceerd; actieplan klaar
(nog niet omgezet in een launcher).** Rol: Diagnostiek-Agent (read-only; géén
launchers of `.sh` geschreven).

Bron: `WERKWIJZE.md`, de aangeleverde werkende opdracht, de twee gamelogs
(één mislukte, één werkende) en twee eigen verificatieruns in deze sessie.
Referentie-prefix is **steigersbouw** (`movedprefixes/ThelastofUsII.rm`, NFS) —
meetlat, geen sjabloon, verdwijnt binnenkort → nu vastleggen.

## Conclusie

- De game **start en werkt** via **GE-Proton11-7**, gestart met de Proton-runner.
  Bewezen: renderer bereikt, **51.4 fps** (aangeleverde run) en **74.9 fps**
  (eigen verificatierun), en de gebruiker bevestigt dat het spel opstart.
- De **enige** noodzakelijke voorwaarde t.o.v. de falende variant is de
  **DXVK/VKD3D-renderer**. De game eist **D3D12 feature level 12_0**; Wine's
  ingebouwde `wined3d` levert maar **11_1** en wordt door de engine afgewezen.
  GE-Proton11-7 brengt DXVK + VKD3D-Proton mee → **12_2** → werkt.
- Er bestaat **nog geen launcher** (`thelastofusii.sh`), **geen icoon** en
  **geen prefix in `~/GAMEPREFIXES/`**.
- **Let op — save-data staat alleen in de prefix.** De bewezen prefix bevat een
  savegame (`savedata/SAVEFILE0P`) en de gebruikersinstellingen (High-preset).
  Verdwijnt `movedprefixes/`, dan is de voortgang weg. **Migreren vóór opruimen.**

## Spel & identiteit

| | |
|---|---|
| Titel | The Last of Us™ Part II (Remastered, Build v1.0.10402.1014) |
| Game-map | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TLoUIIRemastered` |
| EXE | `tlou-ii.exe` — `PE32+ ... x86-64` → **win64** |
| Platform | Steam (repack; `Public/Documents/Steam/RUNE`, ElAmigos) — **geen echte Steam-appid** in de repack |
| Bijzonderheden | `install-script.vdf` → PlayStation SDK (`install_pspc_sdk_runtime.bat`), `psolibs` (PSO-cache, wordt bij uninstall gewist), `crs-*.exe` = PS crash-reporter |
| Frame-generatie/upscalers | FSR (actief), XeSS (`init code = 0`), DLSS/Reflex (NVIDIA/Streamline aanwezig maar inactief) |

## Symptoom (falende variant)

Met **gewone `wine`** (wine-10/11, `wined3d`, géén DXVK) op de prefix-directory
`movedprefixes/ThelastofUsII.rm` (de bovenste, niet-Proton prefix):

- `[Render] Failed to Initialize ADLX`, `[NxApp] Unable to find active GPU`,
  `Failed to get GPU Driver Info`
- Adapter = `ATI Radeon HD 5600 Series` (device `0x68d8`) — een wined3d-fallback,
  niet de echte GPU
- `Number of Supported Adapters: 0`, `Supported : No`,
  **`Max Feature Level : 11_1 [require 12_0]`**
- `[NxStorage] DirectStorage initialization failed`, `[NxUpscaler] XeSS init, code = -1`
- `-[ AMD Driver Info ]-` **`Driver Supported : NO`**
- Het log **stopt direct** na de driver-info: de engine bereikt het rendergedeelte
  nooit (geen "End of settings", geen fps-regel).

## Oorzaak (hoge betrouwbaarheid)

De game is een **DirectX 12 (D3D12) / feature-level 12_0**-titel. Wine's ingebouwde
D3D12/DXGI (`wined3d`) rapporteert maximaal **FL 11_1** → de engine verklaart
**alle** adapters ongeschikt (`Supported: No`) en start de renderer niet.

**GE-Proton11-7** bevat **DXVK + VKD3D-Proton** en rapporteert de echte GPU
(`AMD Radeon RX 7600 XT`, device `0x7480`) op **FL 12_2** → `Supported: Yes`,
`Driver Supported: YES` → de game loopt.

Bewijs dat het om DXVK gaat (en niet om "een andere prefix"): in de Proton-prefix
staan de **DXVK**-DLL's (`dxgi.dll` 4.8 MB, `d3d11.dll` 6.7 MB, `d3d12core.dll`
5.7 MB, `openvr_api_dxvk.dll`), terwijl de falende prefix **wine-builtins** heeft
(`dxgi.dll` 1.5 MB, `d3d11.dll` 3.5 MB). Vulkan zelf is in **beide** gevallen
prima (llvmpipe + `AMD Radeon RX 7600 XT (RADV NAVI33)` worden geënumereerd).

## Bewijs: twee logs, één machine, het verschil is het feature level

Beide logs komen van dezelfde game op dezelfde machine (R7 3700X / RX 7600 XT,
32 GB), alleen de runner/prefix verschilt.

| | **Falend (wine)** | **Werkend (GE-Proton11-7)** |
|---|---|---|
| Log | `/home/peter/Documents/The Last of Us Part II/…log` (2026-10-15 22:48) | `…/movedprefixes/ThelastofUsII.rm/pfx/drive_c/users/steamuser/Documents/The Last of Us Part II/…log` (2026-10-16 08:47) |
| Windows | 10.0 build **19043.0** | 10.0 build **19045.5796** |
| Adapter | `ATI Radeon HD 5600 Series` (0x68d8) | **`AMD Radeon RX 7600 XT`** (0x7480) |
| Adapters/ondersteund | 1 / **0** | 2 / **2** |
| Max feature level | **11_1** [require 12_0] → **No** | **12_2** [require 12_0] → **Yes** |
| DirectStorage | *failed* | *succeeded* |
| XeSS | `code = -1` | `code = 0` |
| Driver Supported | **NO** | **YES** |
| Resultaat | log stopt na driver-info | `End of settings` + **`fps: 51.4`** |

Kopieën van beide logs zijn veiliggesteld in `/tmp/tloui-diag/`
(`wine-run-2248.log`, `proton-run-0847.log`, `proton-run-0900-verify.log`).

### Waarom de twee logs op twee verschillende plekken staan (belangrijk)

De twee prefixes staan **in dezelfde map gestapeld**:

- **Bovenste (dood)**: `movedprefixes/ThelastofUsII.rm/{system.reg,user.reg,drive_c,dosdevices,userdef.reg}`
  — een gewone **wine**-prefix (21:44–22:48). Zijn `drive_c/users/peter/Documents`
  is een **symlink naar `/home/peter/Documents`** → daarom landde het falende log
  in de echte home.
- **Onderste (bewezen)**: `movedprefixes/ThelastofUsII.rm/pfx/` — de door **Proton**
  aangemaakte prefix (aangemaakt 08:43, `.update-timestamp`, `creation_sync_guard`,
  `system.reg.old`). Zijn `drive_c/users/steamuser/Documents` is een **echte map**
  → daar staat het werkende log + de **savegame**.

Proton gebruikt uitsluitend `$STEAM_COMPAT_DATA_PATH/pfx`. De bovenste wine-resten
zijn **dood gewicht** (enkel verwarrend: twee `system.reg`-bestanden). Dit is
WERKWIJZE-valkuil #6 (self-consistency).

## Werkende recipe (bewezen)

```bash
S="/home/peter/.steam/debian-installation"
PROTON="$S/compatibilitytools.d/GE-Proton11-7/proton"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$S"
export STEAM_COMPAT_DATA_PATH="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/movedprefixes/ThelastofUsII.rm"

cd /mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TLoUIIRemastered
"$PROTON" run tlou-ii.exe        # aangeleverd + door mij bevestigd
```

Eigen verificatieruns in deze sessie (Diagnostiek-Agent):

1. **`proton run tlou-ii.exe`** → game op, `Supported: Yes`, **fps 74.9**.
2. **`proton waitforexitandrun tlou-ii.exe`** → game op (dit is exact wat
   `game-common.sh` als default gebruikt — dus de core-tak volstaat).

Kernpunten:

- **Geen Steam Linux Runtime-wrapper nodig.** Anders dan Witcher3RM start deze game
  met een **kale** `proton run`. De regel `Failed loading SDL3 library.` verschijnt
  wél in de output, maar is hier **niet fataal** (de game loopt door naar 74.9 fps).
  → `GAME_STEAM_RUNTIME` **niet** zetten.
- **`run` én `waitforexitandrun` werken** (beide getest). De core-default
  (`waitforexitandrun`) is dus veilig.
- **Werkmap = game-map.** De core doet `cd "${GAME_WORKDIR:-$GAME_DIR}"`
  (`game-common.sh` regel ~975) — precies de werkmap die de bewezen recipe gebruikte.
- **Geen provisioning nodig.** De bewezen prefix is een **verse** GE-Proton-prefix
  (aangemaakt 08:43) die om 08:46 de game startte. VC-runtimes (`msvcp140`,
  `vcruntime140`, `concrt140`) zitten al in de Proton-prefix; `_CommonRedist/vcredist/2022`
  is dus niet nodig. → **geen `PROVISION_HOOKS`**, **geen `PRE_LAUNCH_HOOKS`**.

## Actieplan voor de Launcher-Builder

### 1. Dun launcher-script `template-scripts/game-launchers/LINUXLAUNCHERS/thelastofusii.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

export GAME_NAME="TheLastOfUsII"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TLoUIIRemastered"
export GAME_EXE="$GAME_DIR/tlou-ii.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="The Last of Us Part II"
export GAME_ICON="TheLastOfUsII.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# --- Proton (verplicht: D3D12 FL 12_0; wined3d levert maar 11_1) ---
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="0"          # repack: geen echte appid; 0 = numerieke compatdata-map
export WINEDEBUG="-all"         # onderdrukt o.a. de niet-fatale SDL3-melding

# GAME_STEAM_RUNTIME bewust NIET gezet: kale proton-run is bewezen; SLR4 niet nodig.
# Geen PROVISION_HOOKS / PRE_LAUNCH_HOOKS (bewezen: verse GE-Proton-prefix volstaat).

source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
```

Toelichting velden:

- **`PROTON_PIN="GE-Proton11-7"`** — de bewezen runner. Zonder pin valt de core terug
  op een andere GE-Proton/Steam-Proton; dat is ongetest. Pin hem.
- **`STEAM_APPID="0"`** — de repack heeft geen appid. De core bouwt
  `compatdata/0` (numeriek) — belangrijk, want `ProtonFixes` leidt de game-id af met
  een regex op cijfers in `STEAM_COMPAT_DATA_PATH`; het bewezen pad had toevallig
  alleen cijfers via `VG_00`. `0` is de robuuste keuze (bewezen run had geen
  game-specifieke fixes nodig). *Als de echte retail-appid van TLOU II Remastered
  bekend is, mag die ook — niet geverifieerd.*
- **`GAME_NAME="TheLastOfUsII"`** — `scan_games()` in `game-gui.py` leidt de naam af
  uit de bestandsnaam van de launcher, dus hou die consistent met script-, icoon-
  en prefixnaam.

### 2. Prefix lokaal per gebruiker — mét de savegame (kritiek)

De bewezen prefix staat op NFS-steigersbouw. Vóór het opruimen van `movedprefixes/`:

1. Maak `~/GAMEPREFIXES/TheLastOfUsII/pfx`.
2. **Migreer de `pfx/`-inhoud** uit `movedprefixes/ThelastOfUsII.rm/pfx`
   (inclusief `drive_c/users/steamuser/Documents/The Last of Us Part II/`
   → `savedata/SAVEFILE0P`, `gamedata`, instellingen).
3. **Neem de bovenste wine-rest NIET over** (`system.reg`, `drive_c`, `dosdevices`,
   `userdef.reg`, de dode `Documents`-symlink) — dat is de kapotte variant.
4. De core maakt bij de eerste start zelf `~/GAMEPREFIXES/TheLastOfUsII/compatdata/0/pfx`
   → symlink naar `~/GAMEPREFIXES/TheLastOfUsII/pfx`.
5. **Verifieer** tegen de referentie zolang `movedprefixes/ThelastOfUsII.rm` nog
   bestaat, en pas daarna opruimen.

Alternatief (alleen als de voortgang niet bewaard hoeft te blijven): een **verse**
prefix werkt ook — bewezen met de verse prefix van 08:43. Maar dat kost de save.

### 3. Icoon

Geen icoon in de game-map (`launcher_00.ico` is Windows-formaat, niet bruikbaar).
Lever een **512×512 PNG met transparantie** aan als
`template-scripts/game-launchers/gameicons/TheLastOfUsII.png`.

### 4. Desktop-shortcut

Regelt de core via `CREATE_DESKTOP_SHORTCUT="1"` + `GAME_ICON`. Daarna de
`.desktop`-test uitvoeren (shortcut + spelstart).

### Optioneel (alleen bij klachten, niet bewezen nodig)

- `GAME_GAMESCOPE="1"` — alleen als op AMD/Wayland een exclusive-fullscreen
  focus-stall optreedt (zoals bij Cities: Skylines / Ori). Nu **niet** nodig.
- `DXVK_HUD` — niet nodig, en het spel heeft eigen FPS-weergave.

## Terugdraaien

- Launcher weg: `rm .../LINUXLAUNCHERS/thelastofusii.sh` (raakt prefix/spel niet).
- Prefix opnieuw: `rm -rf ~/GAMEPREFIXES/TheLastOfUsII`.
- De game-bestanden blijven op de NFS-share staan.

## Wat NIET de oorzaak bleek

- **De prefix-bestanden zelf / "een verse prefix crasht".** Een verse GE-Proton-prefix
  start de game juist wél — de oorzaak zit in de **runner** (wine/wined3d vs.
  Proton/DXVK), niet in ontbrekende prefix-inhoud.
- **`Failed loading SDL3 library.`** — verschijnt, maar is hier **niet** fataal
  (in tegenstelling tot Witcher3RM, waar kale `proton run` hierop afbrak). Geen
  Steam Linux Runtime-wrapper nodig.
- **DllOverrides / `winetricks` / `_CommonRedist`-redists.** Niet nodig: de verse
  Proton-prefix liep direct.
- **Vulkan.** In beide runs beschikbaar (llvmpipe + RADV); het probleem is de
  D3D12-**feature level** die wined3d niet haalt, niet het ontbreken van Vulkan.
- **vkBasalt / overlays.** vkBasalt is op deze machine globaal actief (logruis) en
  onschuldig.
- **`Invalid window handle` op de keyboard-layout registersleutel** (falende run) en
  de PS-DBUs-meldingen — bijkomstig, niet fataal.
- **`crs-handler.exe`** (PlayStation crash-reporter) draait altijd mee naast de game;
  onschuldig (probeert alleen naar playstation.com te uploaden).

## Restrisico / te verifiëren vóór `movedprefixes/` verdwijnt

1. **Savegame-migratie** (punt 2 hierboven) — zonder dit is de voortgang weg.
2. **`STEAM_APPID`** — `0` is bewezen-veilig; een echte appid is niet geverifieerd.
3. **Icoon** — nog niet aangeleverd.

## Overdracht

Oorzaak bewezen en tweemaal gereproduceerd → **doorverwijzen naar de
Launcher-Builder Agent** voor uitvoering van het actieplan. Dit document is de
enige output van de Diagnostiek-Agent.
