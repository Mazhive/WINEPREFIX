# BEVINDINGEN — Tomb Raider: Game of the Year Edition (2013)

Datum: 2026-10-10. Status: **analyse afgerond, actieplan klaar (nog niet geverifieerd
op een verse prefix).** Bron: WERKWIJZE.md, de werkende referentie
`movedprefixes/TombRaiderGOTY/pfx`, de geslaagde testrun (DXVK-logs in de gamemap,
2026-10-10 14:48) en de bestaande template-scripts (launcher + hooks).

## Conclusie

De game is **speelbaar** en er is een **bewezen werkende referentie**:
`movedprefixes/TombRaiderGOTY/pfx` (win64/WoW64, DXVK + d3dx9/d3dx10/d3dx11 + vcrun6).
Er bestaat nog **geen launcher** en **geen prefix in `~/GAMEPREFIXES/`**. De volgende
stap is een dunne launcher die een verse win64-prefix bouwt met dezelfde effectieve
set (DXVK + DirectX-hulplibs) en de game met cwd = gamemap start.

## Game-analyse

- **`TombRaider.exe`** = **PE32 (32-bit)**, Intel i386, 2013 (`TRASBUILD-v4`,
  2013-05-14). 32-bit in een win64-prefix (WoW64) is normaal.
- **Renderer: D3D11, dynamisch geladen.** De statische importlijst bevat géén
  `d3d11.dll`/`dxgi.dll`/`d3d9.dll`, maar de strings `d3d11.dll`, `d3d9.dll` en
  `dxgi.dll` zitten wél in de exe. Bewijs van een echte D3D11-run staat in de gamemap:
  `TombRaider_d3d11.log` + `TombRaider_dxgi.log` (DXVK **v1.6**, 1920×1080, exclusive
  fullscreen, 4233 state-cache-entries) en `TombRaider.dxvk-cache` (1 MB).
- **Overige statische imports:** `binkw32.dll` (Bink-video), `fmodex.dll` (FMOD-audio),
  `MSVCR90.dll`/`MSVCP90.dll` (VC++ 2008 — **lokaal meegeleverd** in de gamemap),
  `steam_api.dll` (Steamworks), `WINMM`, `DSOUND`-achtig, standaard Win32.
- **Media:** `movies/*.bik` (Bink) en `DLC/*.tiger`. Bink wordt door `binkw32.dll`
  afgespeeld; **geen `mf`/Media Foundation nodig**.
- **Config:** de game schrijft zelf naar
  `HKCU\Software\Crystal Dynamics\Tomb Raider\Graphics` en `\Controls` (aanwezig in de
  referentie). Een verse prefix heeft die sleutels niet; de game maakt ze bij de eerste
  run zelf aan → **geen pre-launch register-hook nodig**.
- **Install-register:** `HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Tomb Raider GOTY Edition_is1`
  met `InstallLocation` = de gamemap. Dit is alleen de uninstall-vermelding; de game
  start ook zonder (te bevestigen in de verificatie).

## Bewijs: werkende referentie

`movedprefixes/TombRaiderGOTY/pfx` hoort bij deze game (dosdevice `f:` →
`/media/peter/Tomb Raider GOTY`, install-keys naar de gamemap).

| Eigenschap | Waarde |
|---|---|
| Architectuur | `#arch=win64` (WoW64) |
| winetricks.log | `d3dx10_43`, `d3dx11_43`, `dxvk`, `d3dx9_43`, `vcrun6` |
| DllOverrides (user.reg) | `*d3d10`, `*d3d10_1`, `*d3d10core`, `*d3d11`, `*d3dx10_43`, `*d3dx11_43`, `*d3dx9_43`, `*dxgi` = **native**; `msvcrtd` = native |
| DXVK | `d3d11.dll` (3,1 MB) + `dxgi.dll` (2,0 MB) in `syswow64` — **DXVK v1.6** (mrt 2020) |
| dosdevices | `f:` → install-media, `z:` → `/` |

De geslaagde run (2026-10-10 14:48) gebruikte deze DXVK v1.6 en bereikte de presenter
op 1920×1080 zonder fouten (alleen onschuldige `VK_FORMAT_D24_UNORM_S8_UINT`-warnings).

## Actieplan voor de Launcher-Builder

Dun bestand `template-scripts/game-launchers/LINUXLAUNCHERS/tombraidergoty.sh`:

```bash
#!/usr/bin/env bash
# TombRaiderGOTY — Launcher script
set -euo pipefail

export GAME_NAME="TombRaiderGOTY"
export GAME_DISPLAY_NAME="Tomb Raider: Game of the Year Edition"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/TombRaiderGOTYEdition"
export GAME_EXE="$GAME_DIR/TombRaider.exe"
export GAME_ICON="TombRaiderGOTY.png"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Effectieve set uit de referentie: DXVK (d3d11/dxgi/d3d9 native) + DirectX-hulplibs.
export PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "install_d3dcompiler_43")

source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
game_main "$@"
```

**Let op het bronpad:** de launcher staat in `LINUXLAUNCHERS/` (submap van
`game-launchers/`), dus `../../game-core/` is correct. De bestaande kopieën in
`game-launchers/` (zonder `LINUXLAUNCHERS/`) gebruiken óók `../../game-core/` en zijn
daardoor **kapot** — die horen daar niet (zie ook de losse Worms/SOTTR-kopieën).

### Hooks: wat dekt de referentie, wat niet

| Referentie-onderdeel | Beschikbare hook | Opmerking |
|---|---|---|
| `dxvk` | `install_dxvk` | ✅ dekt d3d11/d3d10core/d3d9/dxgi native |
| `d3dx9_43` + `d3dcompiler_43` | `install_d3dx9` (doet beide) | ✅ |
| `d3dx10_43` | — | **geen hook**; game importeert d3dx10 niet statisch → waarschijnlijk niet nodig |
| `d3dx11_43` | — | **geen hook**; idem |
| `vcrun6` | — | geen hook; game importeert `msvcr90`/`msvcp90` (VC++ 2008, lokaal meegeleverd), niet msvcrt/msvcp60 |

De referentie is de bewezen set, maar de game importeert `d3dx10`/`d3dx11`/`vcrun6`
**niet statisch**. Begin daarom met de beschikbare hooks en voeg alleen toe wat de
verificatie aantoont dat nodig is (één variabele per run).

### Icon

De gamemap heeft **geen `.ico`**, maar wel `TRGOTY.jpg` (1280×720). Converteer naar
256×256 PNG met transparante achtergrond en plaats als
`template-scripts/game-launchers/gameicons/TombRaiderGOTY.png`:

```bash
cd template-scripts/game-launchers/gameicons/
python3 jpeg2png.py -d .   # converteert .jpg → .png (transparant)
# hernoem indien nodig naar TombRaiderGOTY.png
```

`GAME_ICON` is expliciet gezet, dus de icon-resolutie in `game-gui.py` is exact.

## Verificatie (één variabele per run)

1. **Premisse meten**: verse `win64`-prefix + `PROVISION_HOOKS=("install_dxvk" "install_d3dx9" "install_d3dcompiler_43")`,
   run. Start de game (menu + gameplay)? Klaar.
2. Zo niet (zwart scherm/crash): **één variabele** toevoegen. Kandidaten in volgorde:
   - `install_vcrun2008` (dekt VC++ 2008; de game levert msvcr90/msvcp90 lokaal, dus
     mogelijk overbodig);
   - een **nieuwe hook** voor `d3dx10_43`/`d3dx11_43` (winetricks `d3dx10 d3dx11`) als
     de game daar om vraagt;
   - `install_win7` alleen bij versie-gevoeligheid.
3. Leg bij elke crash het **fault-adres** vast (niet alleen "er was een crash") en
   vergelijk dat tussen runs (WERKWIJZE-valkuil 2).
4. `.desktop`-shortcut genereren/verifiëren en GUI-detectie controleren.
5. `movedprefixes/` nooit wijzigen: alleen lezen.

## Wat níét nodig lijkt (te bevestigen met de stappen hierboven)

- **Pre-launch register-hook** — de game schrijft `Crystal Dynamics\Tomb Raider\*` zelf.
- **`mf`/Media Foundation** — video is Bink (`binkw32.dll`), geen MF.
- **Proton/GE-Proton** — de referentie draaide op plain wine + DXVK.
- **`install_dotnet48`/`install_vcrun2019`** — geen .NET/MSVC-2015+-imports in de exe.
- **`install_cnc_ddraw`** — de game is D3D11, geen DirectDraw.

## Caveats

- **DXVK-versie**: de referentie is van 2020 (DXVK v1.6). De moderne `winetricks dxvk`
  is veel nieuwer — bewuste afwijking, net als eerder bij CMR4 (`dxvk93` → huidige dxvk).
  Alleen terugschakelen als de nieuwere DXVK regressies geeft.
- **32-bit in win64**: de exe is PE32; `PREFIX_ARCH="win64"` (WoW64) is correct en
  vereist geen 32-bit wine-pakketten.
- **Saves/config**: de game schrijft naar `Saved Games` in de prefix en naar
  `HKCU\Software\Crystal Dynamics\Tomb Raider`. Bij een verse prefix begint de speler
  met lege instellingen (verwacht gedrag).
- **Gamemap is world-writable** (`drwxrwsrwx`); de DXVK-logs/cache belanden in de
  gedeelde NFS-gamemap. Functioneel, maar niet conflictvrij bij gelijktijdig spelen.

## Terugdraaien

- Launcher weghalen en prefix opnieuw bouwen: `rm -rf ~/GAMEPREFIXES/TombRaiderGOTY`.
- `movedprefixes/TombRaiderGOTY/pfx` is read-only meetlat en verdwijnt; deze bevinding
  staat daarom hier.
