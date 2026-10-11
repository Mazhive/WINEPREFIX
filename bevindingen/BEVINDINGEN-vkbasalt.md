# BEVINDINGEN — vkBasalt (vibrance/deband) + kleurbeeld

> Opgesteld door de **Diagnostiek-Agent**. Dit document is een analyse + plan +
> overdracht. De implementatie (GUI/core/hook) is **Launcher-Builder**-werk; de
> Diagnostiek-Agent maakt of bewerkt geen `.sh`/launchers.

## Samenvatting

Op **noa's pc** (CachyOS, NVIDIA **GTX 1080 Ti**) is het beeld "niet best"
(gewassen/grijs, banding). De **primaire oorzaak** is vrijwel zeker de
**RGB-range / WCG / HDR**-instelling van de display (limited 16-235 i.p.v. full
0-255, of WCG/HDR die de kleuren wast) — een **per-machine** instelling, geen
game- of prefix-probleem.

Als **aanvulling** (en generiek voor alle pc's) komt er een **vkBasalt**-checkbox
in de GUI, standaard **uit** (net als MangoHud), met effecten
`Deband:Vibrance:Curves:Tonemap`.

**Belangrijk:** vkBasalt hoeft **niet** systeem-breed geïnstalleerd te worden —
**GE-Proton11-7 bundelt de layer al**. `ENABLE_VKBASALT=1` laat Proton zelf de
layer-path zetten.

---

## Symptoom

- noa's pc: gewassen/grijs beeld, zichtbare kleurbanding in gradients.
- Geldt voor **alle games** op die pc (dus display/GPU-instelling, niet per game).
- 1080 Ti (Pascal) — geen RT-cores; los van de SOTTR-DXR-bevinding.

## Root cause analyse

| Laag | Oorzaak | Fix | Scope |
|------|---------|-----|-------|
| Display (primair) | RGB-range limited i.p.v. full; WCG/HDR wast kleuren | `kscreen-doctor` (Deel B) | noa's pc |
| Display (primair) | Banding door 8-bit output zonder dithering | `nvibrant` dithering | noa's pc |
| Game (aanvullend) | Geen vibrance/deband in de render | vkBasalt-checkbox | alle pc's |

De display-fix is de **echte** oplossing; vkBasalt is aanvulling, geen vervanging.

## Bewijs (uit de omgeving)

- **GE-Proton11-7 bundelt vkBasalt:**
  - `files/share/vkbasalt/implicit_layer.d/vkBasalt.json`
  - `files/lib/x86_64-linux-gnu/libvkbasalt.so` + `files/lib/i386-linux-gnu/libvkbasalt.so`
  - `proton:2343-2345`: `ENABLE_VKBASALT` → Proton voegt
    `share/vkbasalt/implicit_layer.d` toe aan `VK_IMPLICIT_LAYER_PATH`.
  - Layer-json: `enable_environment: ENABLE_VKBASALT=1`,
    `disable_environment: DISABLE_VKBASALT=1`.
- **Config-pad** (via `strings` op `libvkbasalt.so`): `VKBASALT_CONFIG_FILE`,
  anders `$XDG_CONFIG_HOME/vkBasalt/vkBasalt.conf` → `~/.config/vkBasalt/vkBasalt.conf`
  → `~/.local/share/vkBasalt/vkBasalt.conf`.
- Bestaande conf: `~/.config/vkBasalt/vkBasalt.conf` (GOverlay), shader-paden
  aanwezig, `effects =` leeg.
- Systeem heeft **geen** vkBasalt-layer/binary (`/usr/share/vulkan/implicit_layer.d/`
  bevat alleen MangoHud) — niet nodig, want Proton bundelt hem.

## Beslissingen (vergrendeld)

- Generiek voor **alle pc's** (GUI/core-wijziging gedeeld op de NFS-share).
- vkBasalt-conf op de **bestaande locatie** `~/.config/vkBasalt/vkBasalt.conf`
  (dus **geen** `VKBASALT_CONFIG_FILE` nodig).
- Effecten: **`Deband:Vibrance:Curves:Tonemap`**.
- vkBasalt **standaard uit**, per-launch, **niet** gepersisteerd (net als MangoHud).
- **HDR vervalt** (geen hook, geen `GAME_HDR`).

---

## Plan

### Deel A — generiek (alle pc's, gedeeld op NFS)

**A1. `game-gui.py`**
- `_build_options` (~911): `self.cb_vkbasalt = QCheckBox("vkBasalt (vibrance/deband)")`,
  `setChecked(False)`, tooltip.
- Grid (~935): `grid.addWidget(self.cb_vkbasalt, 3, 0)` — vrije cel onder MangoHud
  (MangoHud = index 6 → (2,0); soundtrack staat op (3,1)).
- `extra_env` (~1130): `"GUI_VKBASALT": "1" if self.cb_vkbasalt.isChecked() else "0"`.
- Helptekst (~845): "…, MangoHud, vkBasalt, …".
- Niet persisteren (per-launch, consistent met `cb_mangohud`).

**A2. `game-core/game-common.sh` — `_neutralize_overlays()` (642-658) splitsen**
MangoHud en vkBasalt **onafhankelijk** behandelen:
```
GAME_KEEP_OVERLAYS=1 → return (beide ongemoeid)
MangoHud:  GUI_MANGOHUD=1  → MANGOHUD=1, unset DISABLE_MANGOHUD
           anders          → DISABLE_MANGOHUD=1, unset MANGOHUD
vkBasalt:  GUI_VKBASALT=1  → ENABLE_VKBASALT=1, unset DISABLE_VKBASALT
           anders          → unset ENABLE_VKBASALT
```
- Header-doc (regel 41-45) uitbreiden met `GUI_VKBASALT`.

**A3. `~/.config/vkBasalt/vkBasalt.conf`** (per gebruiker, bestaande locatie)
- `effects = Deband:Vibrance:Curves:Tonemap` (shader-paden staan er al).
- Geen `VKBASALT_CONFIG_FILE`; geen systeem-install van vkBasalt.

**A4. Documentatie**
- Deze bevinding. `README.native-opties.md` **niet** (dat gaat over native-launch).

### Deel B — noa's pc (1080 Ti, CachyOS), handmatig per machine

1. **Diagnose:** `kscreen-doctor -o` → check `RgbRange`, `WCG`, `HDR`, bits.
2. **Grey/washed:** `kscreen-doctor output.<ID>.rgbrange.full`; WCG uit
   (`output.<ID>.wcg.disable`); HDR uit.
3. **Banding:** `nvibrant` dithering.
4. **Vibrance:** `nvibrant` digital-vibrance.
5. **Monitor-OSD:** saturatie/zwart-niveau/picture-mode.

> De exacte `kscreen-doctor`-propertynamen en de `nvibrant`-CLI zijn **aannames**;
> eerst verifiëren op noa's pc. `nvibrant` is een systeem-tool → **niet** in de
> launcher.

### Effecten (vkBasalt)

| Effect | Doet |
|--------|------|
| `Deband` | Haalt kleurbanding/ringen uit gradients |
| `Vibrance` | Slimme kleurverzadiging (washed-out tegen) |
| `Curves` | Contrast/tone-curve (zwarten dieper) |
| `Tonemap` | Tone-mapping, herstelt vlakke look |

## Verificatie (na implementatie, door Launcher-Builder)

- `bash -n` op `game-common.sh`; GUI start zonder fouten.
- SOTTR **met** vinkje → vkBasalt-log + effect zichtbaar; **zonder** vinkje →
  `ENABLE_VKBASALT` niet gezet.
- MangoHud aan + vkBasalt uit (en omgekeerd) → onafhankelijk correct.
- noa's pc: `kscreen-doctor -o` → RgbRange full / WCG uit; desktop-gradients
  visueel minder ringen.

## Wat níét de oorzaak bleek / valkuilen

- **Systeem-install van vkBasalt is onnodig** — GE-Proton11-7 bundelt de layer.
  (De systeem-layer ontbreekt hier zelfs.)
- **`ENABLE_HDR_WSI` is een gamescope-var**, niet Proton; HDR vervalt sowieso.
- **`_neutralize_overlays()` mag MangoHud en vkBasalt niet in één if/else
  stoppen** — de oude else-tak `unset ENABLE_VKBASALT` zou vkBasalt uitzetten
  zodra MangoHud uit staat.
- **`README.native-opties.md` is native-only** — niet gebruiken voor deze
  Proton/algemene optie.

## Overdracht

- **Diagnostiek-Agent:** analyse + dit document. Klaar.
- **Launcher-Builder:** voer Deel A uit (`game-gui.py`, `game-common.sh`,
  `~/.config/vkBasalt/vkBasalt.conf`) en verifieer. Deel B is handmatig op noa's pc.
