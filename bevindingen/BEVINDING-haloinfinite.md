# BEVINDING — Halo Infinite

Datum: 2026-10-09. Status: **opgelost, game start en laadt (spinner) op NVIDIA.**
Werkmethode: `WERKWIJZE.md` in deze map. Productie-prefix: `~/GAMEPREFIXES/haloinfinite/pfx`.
Aanleiding: de gedeelde launcher werkte op deze pc (AMD) wel en op `noa@192.168.4.22`
(NVIDIA) niet.

## Symptoom

Op de NVIDIA-pc (CachyOS, GTX 1080 Ti, driver 580.178.04) stopt de launch direct na
de D3D12-device-init. De launcher meldt `GAME START MISLUKT`; het spel schrijft zijn
eigen crashmelder weg:

```
AppData/Local/Temp/crash_game_<ts>/crash.txt
type = crash
project = SHIVA
build = 6.10020.17952.0
branch = HIFLTA
```

Er is **geen** `Unhandled page fault`/fault-adres: de game kiest zelf de exit (code 10),
zonder SEH-fout in het Proton-log. `WINEDEBUG=-all` verbergt dat bovendien.

Op de AMD-pc (Radeon RX 7600, Mesa/RADV) start de game normaal.

## Differentiatie (aftrekkend)

Beide pc's hadden alles wat de launcher vereist identiek op orde:

- NFS `PUBLIC-LIBRARY` gemount, `HaloInfinite.exe` bereikbaar
- `GE-Proton9-27` aanwezig en `proton` uitvoerbaar
- wine / winetricks / curl / wget aanwezig
- prefix geprovisiond (marker v1): alle MSVC-DLL's **én** `d3d12.dll`/`d3d12core.dll`/
  `dxgi.dll` als x86_64 in `system32`, geen schaduw-DLL's naast de exe
- KDE Plasma Wayland-sessie aanwezig

Het enige structurele verschil: **GPU/driver**. In het vkd3d-proton-log:

| | AMD (RADV) | NVIDIA (Pascal) |
|---|---|---|
| Shader model | SM 6.6/6.7/6.8 | SM 6.6 (pre-Turing-waarschuwing) |
| Feature level | `DX Ultimate supported!` | niet gemeld |
| NVAPI | afwezig | **DXVK-NVAPI 0.9.0 geladen** |

Op NVIDIA roept het spel `NvAPI_D3D12_CreateHeap` aan; DXVK-NVAPI antwoordt
`Not implemented method` (`NVAPI_NO_IMPLEMENTATION`). Daarna stopt het spel.

## Oorzaak

**DXVK-NVAPI.** Halo Infinite neemt op een NVIDIA-GPU het NVAPI-pad en roept
`NvAPI_D3D12_CreateHeap` aan, een methode die DXVK-NVAPI 0.9.0 niet implementeert.
De game crasht daarop direct na de D3D12-device-init. Op AMD is NVAPI afwezig, kiest
Halo het generieke pad en werkt het.

Het is dus **geen** launcher-, prefix- of provisioning-probleem; het verschil zit in
de aanwezigheid van NVAPI op NVIDIA.

## Fix

In `template-scripts/game-launchers/LINUXLAUNCHERS/haloinfinite.sh`, naast
`PROTONFIXES_DISABLE`:

```bash
export PROTON_DISABLE_NVAPI="1"
```

Halo gebruikt dan het generieke D3D12-pad. Op AMD is dit een no-op (daar is NVAPI
sowieso niet actief), dus de regel mag onvoorwaardelijk in de gedeelde launcher.

### Vereiste aanpassingen voor de launcher

- **Nieuwe hook:** géén. Er is geen provision- of pre-launch-hook nodig; de fix is
  één omgevingsvariabele.
- **Aanpassing in `haloinfinite.sh`** (naast `PROTONFIXES_DISABLE=1`):
  ```bash
  export PROTON_DISABLE_NVAPI="1"
  ```
- **Behouden zoals het is:** `PROTON_ENABLED=1`, `PROTON_PIN="GE-Proton9-27"`,
  `STEAM_APPID="1240440"`,
  `PRE_PROVISION_HOOKS=("ensure_geproton9_27")`,
  `PROVISION_HOOKS=("install_haloinfinite_vcrun")`,
  `PRE_LAUNCH_HOOKS=("haloinfinite_stray_dlls")`. Deze zijn niet de oorzaak en
  horen te blijven staan.

## Verificatie

- **Isolatietest (één variabele):** remote-launcher met alleen `PROTON_DISABLE_NVAPI=1`
  → `timeout` moest de game na 60 s nog afbreken (exit 124 = draaide), geen nieuwe
  `crash_game_*`-map (20 → 20), geen NVAPI-regels meer in het log.
- **Bevestiging op .22:** het spel toont de **laadspinner** — het start.
- De AMD-pc blijft ongewijzigd werken.

## Wat níét de oorzaak bleek

- **De prefix / provisioning.** Op .22 volledig geprovisiond en gezond (v1), alle
  vereiste DLL's x86_64 aanwezig.
- **De NFS-share of het installatiepad.** Game-map en exe bereikbaar.
- **GE-Proton9-27.** Aanwezig en uitvoerbaar op beide pc's.
- **De grafische sessie.** Beide KDE Plasma Wayland.
- **`ProtonFixes` `.../protonfixes does not exist`** (alleen op .22): cosmetische
  waarschuwing; `PROTONFIXES_DISABLE=1` staat al aan.
- **`SDL Dynamic API Failure!`**: verschijnt op **beide** pc's en is onschadelijk
  (SDL valt terug op de standaard).
- **`concrt140.dll`/VC-runtime**: de MSVC-DLL's stonden correct in `system32`; geen
  schaduw-DLL's naast de exe.
- **Shader-model/feature-level alleen**: genoemd als verschil, maar de crash verdween
  al door NVAPI uit te zetten — niet door de feature-level te veranderen.

## Terugdraaien

- Launcher terug: `export PROTON_DISABLE_NVAPI="1"` verwijderen (of een regel
  `export PROTON_DISABLE_NVAPI="0"` zetten).
- Prefix weggooien en opnieuw bouwen: `rm -rf ~/GAMEPREFIXES/haloinfinite`.
- Let op: `movedprefixes/` is alleen meetlat en verdwijnt; deze bevinding staat
  daarom hier en niet daar.
