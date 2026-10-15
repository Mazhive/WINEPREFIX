# BEVINDING — Halo: The Master Chief Collection (Halo Reach, CODEX)

Datum: 2026-10-14. Status: **oorzaak vastgesteld, spel start met de juiste werkmap.**
Werkmethode: `WERKWIJZE.md`. Analyse-prefix: `movedprefixes/halo.mcc` (alleen als meetlat gebruikt,
niets in gewijzigd).
Spelpad: `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/HaloTheMasterChiefCollectionHaloReach/`

## Symptoom

De CODEX-launcher wordt gestart met een absoluut pad naar de exe, maar de shell staat in een
andere map:

```bash
WINEPREFIX=/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/movedprefixes/halo.mcc \
  wine //mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/HaloTheMasterChiefCollectionHaloReach/mcclauncher.exe
```

Er verschijnt een foutmelding en het spel start niet. `mcclauncher.exe` toont (via `MessageBoxW`)
de tekst:

```
ERROR !
CreateProcess() failed
```

## Oorzaak

**De werkmap (current working directory) is verkeerd.** `mcclauncher.exe` is een 8 KB CODEX-stub
die het echte spel start met een **relatief pad**:

```
CreateProcessW( "MCC/Binaries/Win64/MCC-Win64-Shipping.exe" )
```

(bewijs: de UTF-16-strings in `mcclauncher.exe` zijn exact `MCC/Binaries/Win64/MCC-Win64-Shipping.exe`,
`CreateProcess() failed` en `ERROR !`; de enige geïmporteerde functies zijn `CreateProcessW`,
`MessageBoxW`, `TerminateProcess`, `GetCurrentProcess`, `SetUnhandledExceptionFilter`.)

Wine neemt de **shell-cwd over** als de Windows-werkmap van het gestarte proces (het zet de cwd
NIET op de map van de exe). Bewezen met:

```
$ (vanuit .../WINEPREFIX)  wine cmd /c cd   ->  Z:\mnt\VG_00\...\WINEPREFIX
$ (vanuit /tmp/opencode)   wine cmd /c cd   ->  Z:\tmp\opencode
```

Wordt de launcher vanuit `.../WINEPREFIX` gestart, dan lost het relatieve pad op tegen de
verkeerde map. In de `WINEDEBUG=+process`-log:

```
CreateProcessInternalW app L"MCC/Binaries/Win64/MCC-Win64-Shipping.exe" cmdline (null)
RtlDosPathNameToNtPathName_U_WithStatus (L"Z:\\mnt\\VG_00\\...\\WINEPREFIX\\MCC\\Binaries\\Win64\\MCC-Win64-Shipping.exe" ...)
get_nt_and_unix_names ... -> ret c000003a          # STATUS_OBJECT_PATH_NOT_FOUND
```

→ `CreateProcess` faalt → `MessageBoxW("ERROR !", "CreateProcess() failed")` → spel start niet.

Het relatieve pad is correct zodra de cwd = de **game-root** is. Vanuit de game-map:

```
CreateProcessInternalW app L"MCC/Binaries/Win64/MCC-Win64-Shipping.exe" cmdline (null)
NtCreateUserProcess ... L"Z:\\mnt\\VG_00\\...\\HaloTheMasterChiefCollectionHaloReach\\MCC\\Binaries\\Win64\\MCC-Win64-Shipping.exe" ...
NtCreateUserProcess ... pid 0328 tid 032c
```

Het spelproces `MCC/Binaries/Win64/MCC-Win64-Shipping.exe` liep daarna (≈1 GB RSS); de game start
dus zodra de werkmap klopt.

## Fix

**Start de launcher vanuit de game-map.** In launchertermen: zet de werkmap op `$GAME_DIR`
vóór de wine-aanroep, of draai `mcclauncher.exe` als `$GAME_EXE` met `cd "$GAME_DIR"` ervoor.

Concreet voor de Launcher-Builder (uitvoering daar, niet hier):

- `GAME_DIR` = `.../WINDOWSGAMES/HaloTheMasterChiefCollectionHaloReach`
- `GAME_EXE` = `"$GAME_DIR/mcclauncher.exe"` (de CODEX-stub op de game-root)
- **Vereist:** een `cd "$GAME_DIR"` (of gelijkwaardige werkmap-instelling) vóór de wine-start,
  anders faalt de CreateProcess van de stub met `c000003a`.

De echte game-exe is `MCC/Binaries/Win64/MCC-Win64-Shipping.exe`; direct starten kan ook, maar dan
moet de cwd alsnog de game-root zijn (de stub verwacht dat pad ook relatief).

## Verificatie

Differentie-experiment, één variabele (cwd), zelfde prefix, zelfde exe:

| cwd | Opgelost pad | Resultaat |
|---|---|---|
| `.../WINEPREFIX` (de foutsituatie) | `...\WINEPREFIX\MCC\Binaries\Win64\MCC-Win64-Shipping.exe` | `c000003a` → `CreateProcess() failed` (geen spel) |
| `.../HaloTheMasterChiefCollectionHaloReach` | `...\HaloTheMasterChiefCollectionHaloReach\MCC\Binaries\Win64\MCC-Win64-Shipping.exe` | `NtCreateUserProcess` ok, pid gestart, spel loopt |

Bevestiging van Wine's cwd-gedrag via `wine cmd /c cd` (zie boven). Geen fault-adres/`Unhandled
page fault` — dit is geen crash maar een CreateProcess-padfout.

## Wat níét de oorzaak bleek

- **De dubbele slash in `//mnt/...`.** Wine accepteert een unix-pad met één of twee leading
  slashes; de bepalende factor is de cwd, niet de `//`.
- **De `win64`-prefix vs. de 32-bit launcher.** `mcclauncher.exe` is PE32 (i386); Wine 11.0 heeft
  `i386-unix`/`i386-windows` en draait hem prima.
- **De prefix of provisioning.** De prefix startte en `MCC-Win64-Shipping.exe` liep; geen
  ontbrekende DLL's, geen registerfout.
- **`setup.exe` "failed to open".** Dat kwam doordat de ISO `/run/media/peter/Halo The Master Chief
  Collection1` op dat moment **niet meer gemount** was (`No such file or directory`); geen
  Wine-probleem en los van deze launcher-fout.
- **`[1014/...ERROR:network_change_notifier_win.cc(156)] WSALookupServiceBegin failed with: 8`**
  in `MCC/Binaries/Win64/debug.log`. Dit is een CEF/Chromium-netwerkmelding
  (network_change_notifier) en is onschadelijk; de game liep met deze regel gewoon.
- **EAC / steam-emu.** Niet de oorzaak; `steam_emu.ini` en `codex64.dll` staan op hun plek en het
  spel startte.

## VC++-runtime (vcrun) — aanvulling

Gevraagd: "welke vcrun hoort geïnstalleerd te zijn?" Antwoord: **VC++ 2017 (v14.0 / MSVC 140)**,
x64 — en die staat **niet** native in deze prefix.

**Wat de game nodig heeft** (imports van de binaries):

| binary | MSVC-runtime-imports |
|---|---|
| `MCC/Binaries/Win64/MCC-Win64-Shipping.exe` | `VCRUNTIME140.dll`, `MSVCP140.dll`, `CONCRT140.dll` + UCRT (`api-ms-win-crt-*`) |
| `MCC/Binaries/Win64/party.dll` | `MSVCP140.dll`, `VCRUNTIME140.dll` + UCRT |
| `MCC/Binaries/Win64/xforgelibrary_release.dll` | `CONCRT140.dll`, `MSVCP140.dll`, `VCRUNTIME140.dll` |
| `MCC/Binaries/Win64/simplenetworklibrary-x64-release.dll` | `CONCRT140.dll`, `MSVCP140.dll`, `VCRUNTIME140.dll` |
| `MCC/Binaries/Win64/cell_release_x64_4_0.dll` | `MSVCP140.dll`, `VCRUNTIME140.dll` |
| `haloreach/haloreach.dll` | `MSVCP140.dll`, `VCRUNTIME140.dll` |

- `mcclauncher.exe` (de 32-bit stub) importeert **geen** MSVC-runtime — alleen kernel32/user32.
- **Geen `vcomp140.dll`** nodig (anders dan Halo Infinite).
- De installer levert de juiste redist mee: `_CommonRedist/vcredist/2017/vc_redist.x64.exe`
  (+ `vc_redist.x86.exe`). Nominaal dus **vcrun2017**. VC++ 2015/2017/2019/2022 delen dezelfde
  14.x-ABI; `vcrun2019`/`vcrun2022` leveren dezelfde DLL's (superset).

**Huidige staat van `movedprefixes/halo.mcc` — runtime is NIET native:**

- `system32/{vcruntime140,vcruntime140_1,msvcp140,msvcp140_1,msvcp140_2,msvcp140_atomic_wait,msvcp140_codecvt_ids,msvcp_win,concrt140,ucrtbase}.dll`
  zijn **byte-identiek aan Wine's builtins** (`/opt/wine-stable/lib/wine/x86_64-windows/…`), bevatten
  de marker `Wine builtin` en geven `file`: `PE32+ executable **for WINE** (DLL), x86-64`.
- `HKCU\Software\Wine\DllOverrides` is **leeg** — er zijn géén overrides voor msvcp140/vcruntime140/
  concrt140/ucrtbase.
- Bewijs met `WINEDEBUG=+loaddll`:
  ```
  Loaded L"C:\windows\system32\vcruntime140.dll" ... : builtin
  Loaded L"C:\windows\system32\MSVCP140.dll"    ... : builtin
  Loaded L"C:\windows\system32\CONCRT140.dll"   ... : builtin
  ```
- De registry liegt: `[Software\Microsoft\VisualStudio\14.0\VC\Runtimes\x64]` staat op
  `"Installed"=1, Major=14, Minor=42 (0x2a)` (14.42), maar Wine laadt alsnog de builtin. De
  "Installed"-sleutel is dus **geen bewijs** dat de native runtime actief is.

**Empirisch resultaat.** Met de builtin-runtime liep `MCC-Win64-Shipping.exe` door tot in de
D3D11-rendering (fixme-storm, 45 s, geen `unimplemented function concrt140`-abort). Voor de
*vroege boot* is native vcrun hier dus **niet bewezen strikt nodig** — anders dan bij Halo Infinite,
waar Wine's `concrt140`-builtin een constructor mist en aborteert. Native vcrun blijft wel de
normale provisioning en aanbevolen vangnet (menu/netwerk/party-code paden kunnen alsnog op een
builtin-gat stuiten).

**Aanbeveling (uitvoering door Launcher-Builder, niet hier):**

- Provision native vcrun in de verse prefix, bijv. `PROVISION_HOOKS=("install_vcrun2019")`, of een
  Halo-stijl hook met `winetricks -q vcrun2022` + DllOverrides
  (`concrt140=native`, rest `native,builtin`) — zie
  `template-scripts/game-core/hooks/install_haloinfinite_vcrun.sh`.
- **Offline beschikbaar** in de winetricks-cache: `vcrun2019` én `vcrun2022` (`vc_redist.x64.exe` +
  `vc_redist.x86.exe`). `vcrun2017` is **niet** gecached → gebruik `vcrun2019`/`vcrun2022`.
- **Blinde vlek om te weten:** `_dll_is_x86_64()` in `template-scripts/game-core/game-common.sh`
  keurt een Wine-builtin goed (het is een geldige PE32+/x86-64). Een haloinfinite-achtige
  `_hi_validate` meldt dus "runtime volledig" terwijl er alleen builtins staan. Wil je écht native
  valideren, check dan op de afwezigheid van de `Wine builtin`-marker of vergelijk de hash/grootte
  met `/opt/wine-stable/lib/wine/x86_64-windows/`.

**Verificatie van deze aanbeveling (2026-10-14, tegen broncode en cache):**

- `template-scripts/game-core/hooks/install_haloinfinite_vcrun.sh` bevestigt het recept: het levert
  via `winetricks -q vcrun2022` (of de gebundelde redist) en zet in `_hi_set_overrides()` de
  DllOverrides — `concrt140=native`, de rest `native,builtin` (regels 30-32 en 72-82). Exact zoals
  hierboven aanbevolen.
- `_dll_is_x86_64()` (`template-scripts/game-core/game-common.sh:265-273`) toetst alleen op
  `file -b` → `PE32+ executable` + `x86-64`; een Wine-builtin voldoet daaraan. De `_hi_validate()`
  van de hook meldt dus "MSVC-runtime volledig en geldig" ook als er uitsluitend builtins staan —
  de blinde vlek is bevestigd.
- Winetricks-cache (`~/.cache/winetricks/`): `vcrun2019/` en `vcrun2022/` bevatten beide
  `vc_redist.x64.exe` + `vc_redist.x86.exe`; er is **geen** `vcrun2017/`-map. Offline-claim
  bevestigd.

## Terugdraaien

Er is **niets** in de prefix of de game gewijzigd dat teruggedraaid moet worden. De fix is
uitsluitend de werkmap vóór de start. `movedprefixes/halo.mcc` is als analyse-referentie gebruikt
en blijft onaangeroerd (meetlat, geen sjabloon).

## Actieplan voor de Launcher-Builder

1. Nieuwe per-game launcher `HaloTheMasterChiefCollectionHaloReach.sh` volgens de boilerplate.
2. `GAME_EXE` → `mcclauncher.exe` op de game-root; `GAME_DIR` → de game-root hierboven.
3. **Kernpunt:** `cd "$GAME_DIR"` (werkmap = game-root) vóór de wine-start, anders
   `CreateProcess() failed`. Als `game-common.sh` een `wine start /unix ...`-pad gebruikt, zorg dat
   de werkmap daar ook op `$GAME_DIR` staat.
4. **VC++-runtime:** provision native vcrun (aanbevolen `PROVISION_HOOKS=("install_vcrun2019")`, of
   vcrun2022 + DllOverrides `concrt140=native`). Redist 2017 zit gebundeld in `_CommonRedist`, maar
   de prefixkandidaat had alleen Wine-builtins (zie de vcrun-sectie). Offline bruikbaar:
   `vcrun2019`/`vcrun2022` uit de winetricks-cache.
