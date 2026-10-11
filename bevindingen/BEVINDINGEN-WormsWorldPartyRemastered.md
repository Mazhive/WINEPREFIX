# BEVINDING — Worms World Party Remastered

Datum: 2026-10-11
Rol: Diagnostiek-Agent (read-only; geen launchers/.sh geschreven, geen Wine-run uitgevoerd).
Status: **Bevestigd via testomgeving** (kopieën van hook + `game-common.sh` in `/tmp/opencode/worms-diag`). Runtime-visuele toets (spel echt starten) is uitgevoerd; resultaat staat in de sectie "Runtime-observatie" hieronder.
Bronnen: `w2_d3d9.log`, `movedprefixes/32.bit.worms.worldparty`, prefix-register, `game-common.sh`, `wormsworldpartyremastered.sh`, hooks, `WERKWIJZE.md`, testomgeving `/tmp/opencode/worms-diag`.

## Symptoom

Bij start van Worms World Party Remastered (`w2.exe`) verschijnt **geen normaal beeld**.
Vermoe­den van de gebruiker: gamescope met de correcte monitorresolutie gebruiken zodat
gamescope het spel kan scalen.

## Omgeving (gemeten)

- Sessie: **Wayland** (`DISPLAY=:1`, `WAYLAND_DISPLAY=wayland-0`).
- Monitor **DP-1** primary **1920x1080 @ 239.66 Hz** (native mode = 1920x1080).
- GPU: **AMD Radeon RX 7600** (Navi 33). Wine **11.0**, gamescope **3.16.24**.
- Prefix: `~/GAMEPREFIXES/WormsWorldPartyRemastered/pfx`, `#arch=win64`.
- DllOverrides `d3d8`/`d3d9`/`d3dx9*` = **native** (DXVK in `system32\d3d9.dll`), winetricks: `dxvk, d3dcompiler_43, d3dx9`.
- `w2.exe` = **PE32 i386** (32-bit); engine rendert via **D3D9** (geen DirectDraw).

## Bewijs

1. **Spel vraagt 640x480 fullscreen** — `WINDOWSGAMES/WormsWorldPartyRemastered/w2_d3d9.log`:
   `ResetSwapChain ... Width: 640 / Height: 480 ... Windowed: false`,
   `Setting display mode: 640x480@0` → `Restoring display mode: 640x480@60`.
2. **Huidige prefix heeft géén spel-optiessleutel** — `grep Team17Digital user.reg` = **0 hits**.
   De game valt dus terug op zijn ingebouwde default (640x480).
3. **Werkende referentie** `movedprefixes/32.bit.worms.worldparty/pfx/user.reg` toont de juiste configuratie:
   - `LastKey = HKCU\Software\Team17DigitalLTD\WormsWorldParty\Options`
   - `[Software\Team17DigitalLTD\WormsWorldParty\Options]`:
     `DisplayXSize=dword:00000400` (1024), `DisplayYSize=dword:00000300` (768),
     `DisplaySize=2`, `vSync=0`
   - `[Software\Wine\Explorer] "Desktop"="Default"` + `Desktops\Default="800x600"` (kleine Wine-desktop)
   - DllOverrides `*d3d9`/`*d3dx9_*` = native; **geen** `ddraw`-override.
4. **Waardennamen bevestigd in de binary** — `strings w2.exe` bevat `DisplaySize`,
   `DisplayXSize`, `DisplayYSize`, `CD Tracks` (exact de referentiewaarden).
5. **Huidige launcher** `LINUXLAUNCHERS/wormsworldpartyremastered.sh` zet:
   `GAME_GAMESCOPE=1`, `GAME_GAMESCOPE_RES=1920x1080`, `WINE_VIRTUAL_DESKTOP=1`, `WINE_DESKTOP_W/H=1920x1080`,
   en `PROVISION_HOOKS=(install_dxvk install_d3dx9 install_gamescope disable_winebus install_cnc_ddraw install_virtual_desktop set_graphics_resolution)`.
6. **Gamescope wordt stil overgeslagen** — `game-core/game-common.sh:1113-1120`:
   eerst `wine_cmd=("${gscope[@]}" wine)`, maar bij `WINE_VIRTUAL_DESKTOP=1` volgt
   `wine_cmd=(wine explorer /desktop=...)` → **de hele array wordt overschreven en `${gscope[@]}` verdwijnt**.
   Met `WINE_VIRTUAL_DESKTOP=1` draait gamescope dus **niet**.
7. **Verkeerde registersleutel én waarden** — `hooks/set_graphics_resolution.sh` schrijft naar
   `HKCU\Software\Team17\Worms World Party\Options` met `Graphics Width`/`Graphics Height`.
   De game leest `HKCU\Software\Team17DigitalLTD\WormsWorldParty\Options` met `DisplayXSize`/`DisplayYSize`
   (zie bewijs 3 en 4). Beide fout → de resolutie wordt **nooit** toegepast.

## Testbewijs (testomgeving `/tmp/opencode/worms-diag`)

Kopieën: `game-common.test.sh`, `set_graphics_resolution.test.sh` (+ `game-conf.sh`).
Scratch-prefix: `pfx-test` (verse `wineboot -i`). Productie-prefix en `movedprefixes/` niet aangeraakt.

**Test 1 — hook schrijft naar verkeerde sleutel (`test-hook.sh`):**
- Na `hook_run()`: `HKCU\Software\Team17\Worms World Party\Options` **bestaat** met
  `Graphics Width=0x780` (1920) en `Graphics Height=0x438` (1080).
- `HKCU\Software\Team17DigitalLTD\WormsWorldParty\Options` → `reg: Unable to find the specified registry key` (**bestaat niet**).
- `user.reg` bevat alleen de verkeerde sleutel. → **Bewijs A bevestigd.**

**Test 2 — gamescope-drop bij virtual desktop (`test-gscope.sh`, fake `wine` die argv print):**
- `WINE_VIRTUAL_DESKTOP=1`: log meldt "Gamescope-wrap actief … res=1920x1080", maar de
  feitelijke command is `explorer /desktop=WormsDiagTest,1920x1080 w2.exe` → **geen gamescope**.
- `WINE_VIRTUAL_DESKTOP=0`: gamescope start daadwerkelijk (`gamescope -f -W 1920 -H 1080 --`)
  en draait de game als child. → **Bewijs B bevestigd.**

**Test 3 — fix-verificatie op `pfx-test`:**
- Schrijven van `DisplayXSize=1024`, `DisplayYSize=768`, `DisplaySize=2`, `vSync=0` naar
  `HKCU\Software\Team17DigitalLTD\WormsWorldParty\Options` → `reg query` toont exact de
  referentiewaarden (0x400/0x300/0x2/0x0). → **Fix-voorstel is geldig.**

## Oorzaak

Meervoudig; samen verklaren ze het "geen normaal beeld":

- **A. Resolutie wordt nooit gezet.** De hook schrijft naar een verkeerd pad én verkeerde
  waardennamen; de game blijft op zijn default **640x480**.
- **B. Geen werkende scaler.** Doordat de virtual-desktop-tak `GSCOPE_ARGV` weggooit
  (`game-common.sh:1120`), draait de 640x480-fullscreen **zonder gamescope** en wordt niets
  naar 1920x1080 opgeschaald.
- **C. Dubbele opsluiting.** `GAME_GAMESCOPE=1` + `WINE_VIRTUAL_DESKTOP=1` is overbodig en
  conflicterend; kies één laag (conform de eerdere feedback in dit bestand en WERKWIJZE.md).
- **D. cnc-ddraw is irrelevant.** De Remastered is een **D3D9**-spel; `install_cnc_ddraw`
  (`ddraw.dll`) draagt niets bij.

## Fix (uit te voeren door de **Launcher-Builder Agent** — niet door de Diagnostiek-Agent)

1. **Gamescope als enige opsluit/scaling-laag.** Zet `WINE_VIRTUAL_DESKTOP="0"` (of verwijder),
   houd `GAME_GAMESCOPE="1"` en `GAME_GAMESCOPE_RES="1920x1080"` (= native DP-1). Gamescope
   schaalt de lage spel-resolutie naar 1920x1080 fullscreen (`-f -W 1920 -H 1080`).
2. **Herstel de gamescope-drop** in `game-core/game-common.sh` (rond regel 1113-1120): behoud
   `"${gscope[@]}"` bij de virtual-desktop-tak (bv. `wine_cmd=("${gscope[@]}" wine explorer /desktop=...)`),
   of — voorkeur — sta VD en gamescope nooit tegelijk toe.
3. **Repareer `hooks/set_graphics_resolution.sh`:**
   - Pad: `HKEY_CURRENT_USER\Software\Team17DigitalLTD\WormsWorldParty\Options`
   - Waarden: `DisplayXSize` en `DisplayYSize` (REG_DWORD), optioneel `DisplaySize`.
   - Kies een door het spel ondersteunde **4:3**-resolutie (referentie: **1024x768**), niet
     1920x1080. Gamescope schaalt 1024x768 → 1920x1080 (pillarbox).
4. **Haal `install_cnc_ddraw` uit `PROVISION_HOOKS`.** Laat `install_dxvk`/`install_d3dx9` staan.
5. **Eén variabele per run** (WERKWIJZE.md): test eerst **alléén** gamescope (VD uit), daarna pas
   de registerwaarden. Vergelijk het resultaat/beeld, niet de exit-code.

## Terugrolmogelijkheid

- Zet `WINE_VIRTUAL_DESKTOP` terug op `1` en/of verwijder de `GAME_GAMESCOPE*`-exports.
- Verwijder desnoods de nieuw geschreven sleutel `HKCU\Software\Team17DigitalLTD\WormsWorldParty\Options`.
- De prefix blijft intact; `movedprefixes/` is uitsluitend gelezen, niets aangeraakt.

## Wat **niet** de oorzaak bleek

- **cnc-ddraw/ddraw**: niet nodig; het spel gebruikt D3D9.
- **DXVK**: correct aanwezig (`d3d9` native); er is geen crash/page-fault — het symptoom is
  beeld/layout, geen memory-fout.
- **Prefix-architectuur**: de referentie is óók `#arch=win64`, dus win64 is geen probleem.
- **Monitorresolutie**: 1920x1080 in de launcher is juist voor scaling; het probleem is dat
  gamescope **niet draaide** en de resolutie niet werd toegepast.

## Runtime-observatie (2026-10-11, door gebruiker)

- Het **hele game-menu is zichtbaar** (mogelijk 1 menu-optie).
- Bij **"back" drukken in het menu** verschijnen opnieuw **zwarte balken met een wit scherm in het midden**.
- **Actieve configuratie tijdens deze test: onbekend** (niet genoteerd). Geen conclusies aan verbonden tot de configuratie is vastgesteld en herhaald.

## Nog te verifiëren (runtime, ≤120 s per run)

- **Premisse-toets (open):** bevestig dat met **VD uit + gamescope aan** wél een geschaald
  beeld verschijnt. De code-claims (A en B) zijn bevestigd; het eindbeeld is nog niet getoetst.
- Bevestig via `reg query` dat de game `DisplayXSize`/`DisplayYSize` overneemt na de fix.
- Noteer welke bron-resolutie de game kiest (640x480 vs 1024x768) om de gamescope-scaler te dimensioneren.

---

**Overdracht:** diagnose afgerond. Voorstel voor hooks/launcher/register staat hierboven;
implementatie hoort bij de **Launcher-Builder Agent**.
