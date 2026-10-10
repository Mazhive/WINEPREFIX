# BEVINDINGEN — Myst 2021 Remake

Datum: 2026-10-09. Status: **opgelost, game start en speelbaar (menu + gameplay + geluid)**.
Bron: **enkel de werkende one-liner** (geen andere logs/analyses).

## Symptoom

Een verse Wine-prefix (alleen `wineboot -i`) laat `Myst-Win64-Shipping.exe` crashen of hangen:
- Zonder provisioning: `dx12 not supported on your system` fout, geen venster.
- Met `dxvk` (zonder `-d3d11`): shader-compilatie, D3D12-pad gekozen → crash/zwart scherm.

## Differentiatie (aftrekkend, uit de one-liner)

De one-liner bouwt een werkende prefix stap voor stap:

| Stap | Commando | Doel |
|---|---|---|
| 1 | `WINEPREFIX=... WINEARCH=win64 wineboot -i` | Verse 64-bit prefix aanmaken |
| 2 | `WINEDLLOVERRIDES="mscoree=;mshtml="` | Gecko/Mono dialogen uitschakelen |
| 3 | `winetricks -q d3dcompiler_43` | Native D3DCompiler_43 (game importeert direct) |
| 4 | `winetricks -q vcrun2019` | VC++ 2019 runtimes (MSVCP140, VCRUNTIME140) |
| 5 | `winetricks -q win7` | Windows 7 mode (CurrentVersion 6.1/7601) |
| 6 | `winetricks -q dxvk` | Native DXVK (d3d9/d3d10core/d3d11/dxgi=native) |
| 7 | `wineserver -w` | Registry flushen vóór launch |
| 8 | `WINEDEBUG=-all wine ... -d3d11` | Start met D3D11 geforceerd |

**Resultaat:** Game start, toont menu, gameplay werkt, geluid werkt.

## Oorzaak

**Myst 2021 Remake (UE4) kiest standaard D3D12.** Op Linux/Wine:
- **wined3d (OpenGL backend)** ondersteunt D3D12 **niet** → `dx12 not supported` fout.
- **dxvk (Vulkan backend)** ondersteunt D3D12 **wel**, maar op AMD RADV leidt D3D12 tot instabiliteit/crash.
- **Oplossing:** Forceer D3D11 met command-line argument `-d3d11`. Dit werkt op zowel wined3d als dxvk.

## Fix specificatie (actieplan voor de launcher)

### 1. Nieuwe launcher aanmaken
Bestand: `template-scripts/game-launchers/LINUXLAUNCHERS/myst2021remake.sh`

```bash
#!/usr/bin/env bash
# Myst 2021 Remake — dxvk + D3D11 forced
# Provisioning: d3dcompiler_43 + vcrun2019 + win7 + dxvk

set -euo pipefail

export GAME_NAME="Myst2021Remake"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Myst2021Remake"
export GAME_EXE="$GAME_DIR/Myst/Binaries/Win64/Myst-Win64-Shipping.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="Myst 2021 Remake"
export GAME_ICON="myst2021remake.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# Wine configuratie
export WINEDEBUG="-all"
export WINEDLLOVERRIDES="mscoree=;mshtml="

# dxvk gebruiken (betere performance op AMD/Vulkan)
export PROTON_ENABLED="0"
export GAME_GAMESCOPE="0"

# Forceer D3D11 (voorkomt D3D12 crash/instabiliteit)
export GAME_WINE_EXTRA_ARGS="-d3d11"

# Provision hooks (éénmalig bij verse prefix)
PROVISION_HOOKS=("install_d3dcompiler_43" "install_vcrun2019" "install_win7" "install_dxvk")
PRE_LAUNCH_HOOKS=()

# Launcher core laden
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"
game_main "$@"
```

### 2. Core-aanpassing (herbruikbaar)
In `template-scripts/game-core/game-common.sh`, functie `game_launch`, Wine-tak (na regel ~1059):
```bash
# Voeg toe vóór "$@":
local wine_extra_args=()
[ -n "${GAME_WINE_EXTRA_ARGS:-}" ] && wine_extra_args+=($GAME_WINE_EXTRA_ARGS)
WINEPREFIX="$PREFIX_PATH" "${wine_cmd[@]}" "$GAME_EXE" "${wine_extra_args[@]}" "$@"
```

### 3. Nieuwe hook
Bestand: `template-scripts/game-core/hooks/install_d3dcompiler_43.sh`
```bash
#!/usr/bin/env bash
# hook: install-d3dcompiler_43 — D3D Compiler 43 (DirectX 10/11 shader compilation).

hook_run() {
  if command -v winetricks >/dev/null 2>&1; then
    _log "hook(install-d3dcompiler_43): winetricks -q d3dcompiler_43..."
    WINEPREFIX="$PREFIX_PATH" winetricks -q d3dcompiler_43 || \
      _log "hook(install-d3dcompiler_43): winetricks gaf non-zero exit; controleer eindstatus."
  else
    _log "hook(install-d3dcompiler_43): winetricks niet gevonden; d3dcompiler_43 niet geïnstalleerd."
  fi
}
```

### 4. Icoon
Plaats `myst2021remake.png` (1024x1024) in `template-scripts/game-launchers/gameicons/`.

### 5. Verificatie
- `rm -rf ~/GAMEPREFIXES/Myst2021Remake`
- Launcher draaien → verse prefix + provisioning + launch
- Bevestigen: menu + gameplay + geluid ≡ one-liner resultaat

## Wat níét nodig bleek (uit one-liner)

- `d3dcompiler_47` / `d3dx9` — game importeert `d3dcompiler_43`, niet 47/43
- `mf` (Media Foundation) — intro-film speelt niet, maar game start wel
- Chroma-spam (`Failed to create effect!`) — Razer Chroma SDK ontbreekt; harmless

