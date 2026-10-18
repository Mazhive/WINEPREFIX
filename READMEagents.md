# WINEPREFIX — Wine-prefix templates voor gedeelde games

Dit systeem laat meerdere gebruikers dezelfde Windows-games draaien vanaf de NFS-share,
zonder dat elke game per gebruiker geïnstalleerd hoeft te worden.

## Kernprincipe

- **Games** staan **op de NFS-share**, gedeeld en leesbaar voor iedereen:
  `WINDOWSGAMES/<Game>/`
- **Wine-prefixen** worden **lokaal en VERS** aangemaakt in `~/GAMEPREFIXES/<Game>/`
  via `wineboot -i` (+ Proton-upgrade als de game via Proton start). Er wordt
  **nooit** een bestaande prefix gekopieerd.
- **Scripts** staan op de share en zijn **modulair**: één keer geschreven, per game
  alleen de game-specifieke config. De scripts zijn de basis/motor van dit systeem
  en werken volledig zelfstandig, zonder GUI.

De reden dat prefixen per gebruiker lokaal moeten staan is door testen vastgesteld:
**alleen de gebruiker die eigenaar is van een prefix kan die prefix starten.**
Prefixen op de NFS-share (zoals de oude `pfx.noa/`, `pfx.djuga/` mapjes) geven
bovendien lock-problemen onder Wine. Daarom: game lees je van de share,
de prefix wordt lokaal eigendom van de speler.

### Referentie-mappen (`movedprefixes/`, `protonprefix/`) — géén runtime-afhankelijkheid

Op de share staan (nog) oude prefix-mappen (`WINEPREFIX/movedprefixes/`,
`PRE-INSTALLED-GAMES/protonprefix/`). Dit zijn **tijdelijk onderzoeksmateriaal**:
ze zijn alleen gebruikt om af te leiden welke extra stappen (hooks, VC++-redists,
appid's) een game nodig heeft. Ze worden **niet** gekopieerd, gelinkt of als
fallback aangeroepen door de scripts, en ze zullen op een gegeven moment van de
server **verwijderd** worden. Elk game-script moet dus blijven werken als deze
mappen niet meer bestaan — dat is ook expliciet getest (verse prefix + Proton
richt zelf alles in, zie per-game-notities hieronder).

## Directory-overzicht

```
NFS-share (gedeeld, read-mostly)
└─ PRE-INSTALLED-GAMES/
   ├─ WINDOWSGAMES/<Game>/        → de game zelf (AngryBirds.exe, Cyberpunk2077.exe, Cities.exe, ...)
   └─ WINEPREFIX/
      ├─ README.md                → deze documentatie
      └─ template-scripts/        → MODULAIRE LAUNCHER-SCRIPTS
         ├─ game-core/
         │  └─ game-common.sh        → HERBRUIKBARE CORE (provision, launch, marker, desktop, Proton-detectie)
         ├─ game-launchers/
         │  ├─ angry-birds.sh        → dun script: wine-mode, geen Proton nodig
         │  ├─ cyberpunk2077.sh      → dun script: Proton-runner + install_vcrun2019-hook
         │  └─ citiesskylines.sh     → dun script: Proton-runner, geen hooks nodig
         └─ tools/
            └─ install-proton.sh     → generiek: installeert/update GE-Proton voor alle games

Lokaal (per gebruiker, eigenaar)
└─ ~/GAMEPREFIXES/
   └─ <Game>/
      ├─ pfx/                     → de eigenlijke Wine-prefix (vers aangemaakt)
      ├─ compatdata/<appid>/      → alleen bij Proton-games (symlink naar pfx/)
      └─ .provisioned             → marker: "provision is al uitgevoerd (versie X)"
```

## Hoe een game start (per gebruiker)

1. De gebruiker draait bijvoorbeeld:
   ```bash
   /mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts/game-launchers/angry-birds.sh
   ```
2. Het script roept de core aan; de core controleert of
   `~/GAMEPREFIXES/AngryBirds/.provisioned` bestaat en of de versie klopt.
   - **Niet bestaat (of oude versie)** → prefix lokaal en **vers** aanmaken
     (`wineboot -i`, eventuele extra stappen zoals VC++2019 via `PROVISION_HOOKS`),
     eigenaar = huidige gebruiker, marker schrijven. Bij Proton-games richt
     Proton bij de eerste start zelf de rest in ("Upgrading prefix from None
     to GE-Proton...") — dxvk/vkd3d/nvapi/ntsync.
   - **Bestaat al** → direct door naar het starten van de game.
   - Er wordt ook meteen een `.desktop`-icoon aangemaakt/bijgewerkt.
3. De game draait dus vanaf de NFS-share, de prefix staat lokaal.
4. **Na de eerste keer provisionen is er geen script/terminal/GUI meer nodig** —
   het `.desktop`-icoon start de game direct met de lokale prefix.

## Modulair ontwerp (belangrijk)

**Alles wat je vaker dan één keer gebruikt, zit in de core — niet in het per-game script.**

`game-common.sh` (core) bevindt zich in `template-scripts/game-core/` en bevat
uitsluitend generieke functies:
- `game_init`                    → variabelen normaliseren, paden afleiden
- `game_needs_provision`        → checkt de marker `$PREFIX_DIR/.provisioned`
- `game_provision`              → prefix **vers** aanmaken (`wineboot -i` + optionele hooks)
- `game_launch`                 → start via `wine` **of** via de Proton-runner (`PROTON_ENABLED=1`)
- `_detect_proton` / `_warn_missing_proton` → zoekt een GE-Proton-runner (PROTON_PIN → hoogste
  GE-Proton → Steam-Proton → umu-run); generieke foutmelding (verwijst naar `tools/install-proton.sh`)
  als er geen gevonden wordt — werkt voor élke game, gebruikt `$GAME_NAME`.
- `game_reprovision`            → marker-versie ≠ script-versie ⇒ opnieuw (vers) provisionen
- `game_make_desktop`           → `.desktop`-shortcut aanmaken; doelmap instelbaar (voor een
  latere GUI die de gebruiker de plek laat kiezen)

Per-game script is daardoor superdun; voorbeeld `angry-birds.sh`
(`template-scripts/game-launchers/`):

```bash
#!/bin/bash
export GAME_NAME="AngryBirds"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/Angrybirds"
export GAME_EXE="$GAME_DIR/AngryBirds.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

source "$(dirname "${BASH_SOURCE[0]}")/../game-core/game-common.sh"
game_main "$@"
```

Een wijziging aan de provision/launch-logica voer je **één keer** door in
`game-common.sh`; elke game neemt die automatisch over.

### Proton-opties (voor DirectX 11/12-games)

```bash
export PROTON_ENABLED="1"                # start via Proton-runner i.p.v. gewone wine
export PROTON_PIN="GE-Proton11-7"        # bewezen werkende versie; anders auto-detect
export STEAM_APPID="1091500"             # echte Steam-appid — nodig voor ProtonFixes
                                          # (anders IndexError bij een gamenaam zonder cijfers)
```
Ontbreekt Proton? Dan verwijst de generieke foutmelding naar
`tools/install-proton.sh` (downloadt/installeert automatisch de laatste
GE-Proton naar `~/.config/heroic/tools/proton/`, en maakt een
`InstallProton`-snelkoppeling).

### Optionele extra stappen per game (hooks)

Sommige games hebben extra onderdelen nodig in de prefix. Dit regelen we via
hooks in `game-core/hooks/<naam>.sh` (elke module definieert `hook_run()`). Er
zijn **drie fasen**, in deze volgorde:

| Fase | Variabele | Wanneer |
|------|-----------|---------|
| Pre-provision | `PRE_PROVISION_HOOKS` | Vóór `wineboot -i`, alleen bij verse prefix |
| Provision | `PROVISION_HOOKS` | Ná `wineboot -i`, alleen bij verse prefix |
| Pre-launch | `PRE_LAUNCH_HOOKS` | Bij **elke** start, vóór `game_launch` |

```bash
export PRE_PROVISION_HOOKS=("install_wine32")   # vóór wineboot -i (bv. 32-bit Wine-check)
export PROVISION_HOOKS=("install_vcrun2019" "install_vkd3d")
export PRE_LAUNCH_HOOKS=("disable_winebus")
```

De core definieert de fasen; het per-game script kiest welke hooks het nodig
heeft. **Let op:** een `*_HOOKS`-variabele die de core niet dispatcht is een
stille no-op (script start, hook draait nooit). Verifieer bij twijfel:

```bash
grep -nE 'PRE_PROVISION_HOOKS|PRE_PROV_HOOKS|PROVISION_HOOKS|PRE_LAUNCH_HOOKS' \
  template-scripts/game-core/game-common.sh
```

`PRE_PROVISION_HOOKS` hoort in `game_init` (flattening naar `PRE_PROV_HOOKS`) én
`PRE_PROV_HOOKS` in `game_provision` (loop vóór `_provision_fresh`);
`PROVISION_HOOKS` in `game_init` (→ `HOOKS`) én `HOOKS` in `_provision_fresh`;
`PRE_LAUNCH_HOOKS` in `game_init` (→ `PRE_HOOKS`) én `PRE_HOOKS` in `game_main`.

## Per-game notities

| Game                  | Renderer         | Opmerking |
|-----------------------|-------------------|-----------|
| **Angry Birds**       | OpenGL 2          | Wine-mode (geen Proton). Runtimes (`msvcp100.dll`, `msvcr100.dll`) liggen al naast de exe. Geen hooks nodig. |
| **Cyberpunk 2077**    | DirectX 12        | Proton-runner (`PROTON_PIN=GE-Proton11-7`, `STEAM_APPID=1091500`). Proton installeert dxvk/vkd3d/nvapi zelf bij de eerste start. Vereist wel de hook `install_vcrun2019` (VC++ 2019, zie `_CommonRedist` in de gamemap) — zonder deze hook stopt de game direct en stil. Bevestigd werkend: hoofdmenu bereikt + toetsenbord. Input: winebus `Enable SDL=0` (pre-launch-hook `disable_winebus`, drift-guard) — de game negeert toetsenbord zodra hij een joystick/controller ziet; SDL-werkenden breken het toetsenbord in álle varianten (getest). **Gamepad:** werkt volledig op OS-niveau (knoppen/assen bewezen via evdev), maar komt in deze opzet NIET in de game: de Xbox-pad heeft geen hidraw-node (xpad-driver) en `/dev/hidraw*` is root-only → Wine kan geen XInput-controller aanbieden; Cyberpunk leest sole XInput en niet de SDL/DInput-joystick. Pad-in-game vereist dus óf éénmalige root (udev-rule 045e:028e op hidraw) óf SteamInput-overlay. |
| **Cities: Skylines**  | DirectX 11 (Unity)| Non-Steam MEX-crack repack. Proton-runner (`PROTON_PIN=GE-Proton11-7`, `STEAM_APPID=255710` — matcht de crack's eigen `MEX.ini`). Enige hook: `install_gamescope` (host-tool voor de wrap; skipt als gamescope al aanwezig is of als er geen root te regelen valt). Verder geen prefix-hooks nodig (game brengt eigen Mono-runtime mee, geen `_CommonRedist`). **Platformfix nodig op AMD/Wayland** (zie werklog): gamescope-wrap (`GAME_GAMESCOPE=1`; res auto-gedetecteerd via xrandr of te pinnen met `GAME_GAMESCOPE_RES="WxH"`) + `dxvk.conf` in de gamemap (`numCompilerThreads=4`, `enableGraphicsPipelineLibrary=True`). Bevestigd werkend: blauwe + witte logo, hoofdmenu, nette eigen afsluiting. Op een NVIDIA/GTX-1070-machine draait hetzelfde script zonder wrap. |
| **Ori: Blind Forest** | DirectX 11 (Unity 5)| CODEX-repack (**origineel**, appid 261570 via `codex.ini`), 32-bit `ori.exe`, Unity **Mono** (`ori_Data/Mono`). Proton-runner (`PROTON_PIN=GE-Proton11-7`). Gamescope-wrap aan — de aanwezige `ori_d3d11.log` toont `Exclusive FS: 1` (zelfde Wayland-stall); res auto-detect. Saves: `AppData\Roaming\Steam\CODEX\261570\remote` (prefix-lokaal). Input: ontworpen rond de controller (XInput **en** DirectInput), maar KBM volwaardig (menu-remap via `KeyRebindings.txt`, `%localappdata%`). DirectInput-mapping v/d originele build is berucht gebroken en niet-Xbox-paden triggers/sticks; winebus-joysticks mijden (default `Enable SDL=0`). |
| **Ori: Will of the Wisps** | DirectX 11 (Unity)| ElAmigos-repack met **twee builds**: UWP/GDK-rest (launch-grdk.bat/wdapp — alleen Windows) én de standalone **PC-build** `oriandthewillofthewisps-pc.exe` (Unity **IL2CPP**, géén Mono/emu-dlls). Proton-runner (`PROTON_PIN=GE-Proton11-7`, `STEAM_APPID=1057090`). Gamescope-wrap aan (DXVK-log: `Exclusive FS: 1`), res auto-detect. Saves: `AppData\LocalLow\Moon Studios GmbH\Ori and the Will of the Wisps`. Bevestigd werkend: boot→menu direct, idle ~5% CPU, nette afsluiting. Input: **XInput-only** en schakelt automatisch naar controllermodus zodra een Xinput-pad aanwezig is (KB dan ondergeschikt); KBM is de door Microsoft aanbevolen route. |


## Steam non-Steam-fusie (het "Forza"-probleem) — samenvatting

**Feit (2026‑09‑20): de fusie is omzeilbaar.** De fusie staat of valt bij één
variabele: een **onbezeten echt store-appid** in `steam_appid.txt`. De omzeiling
is daardoor simpel — het bestand neutraliseren (rename → `steam_appid.txt.disabled`):
de game valt dan vanzelf terug op de bewezen pseudo-appid-route, zonder dat er
iets aan Steam zelf veranderd hoeft te worden. Status: **afgeleid uit eigen
logs + bestands/VDF-onderzoek (2026‑09)**; een gecontroleerde A/B-runtest
(steam_appid.txt = 261570 vs 480) kan dit desgewenst later nog van "afgeleid"
naar "bewezen" tillen (optioneel, bij de GUI-integratie).

**Symptoom (2026, zelf ondervonden):** een non-Steam-shortcut van een
repack-game start niet; Steam meldt "game niet gestart / niet geïnstalleerd"
en hamert op installeren/kopen via de officiële winkel; de shortcut raakt
daarna als store-titel "vast" en is lastig terug te draaien.

**Bewijs in de eigen Steam-logs (console-linux.txt, 2026‑05‑20):**
```
13:02:59 chdir ".../Forza-Horizon-5/"
13:02:59 Game Recording - would start recording game 1551360 ...
13:03:01 ProtonFixes ... UNKNOWN (1551360)      ← sessie gebonden aan het echte store-appid
13:03:23 game stopped ...
13:04:30 AppID 1551360 adding PID ...           ← herpoging
13:04:39 AppID 1551360 no longer tracking PID ... exit code -1 (×20)  ← afgebroken door license-gate
13:04:39 Remove 1551360 from running list
```

**Mechanisme (uit de logs afgeleid):**
- De gamemap bevat een **`steam_appid.txt`**. Steam leest dat en **bindt de
  non-Steam-sessie aan het echte store-appid** (bijv. 1551360 = Forza Horizon 5).
- Bezit je dat appid niet → **license-gate**: de procesketen wordt binnen
  seconden afgebroken (`exit -1`) en de shortcut wordt in de client met de
  store-titel vervlochten (vandaar "niet geïnstalleerd / koop het" en de
  moeite om de shortcut terug te krijgen).
- Games **zonder** `steam_appid.txt` in de map draaien daarentegen als
  **pseudo-appid** (bv. `14879414305781972992`, `5208010`, `4157105450` zichtbaar
  in de logs) → **geen fusie, geen license-gate** → non-Steam-shortcuts werk.

**Betekenis voor deze collectie** (gescand 2026‑09):
- Conflict-dragers (bestand aanwezig → Forza-patroon als je ze als Steam-shortcut
  toevoegt zonder dat je het appid bezit): **Eve Online (8500)**,
  **AOW.Planetfall (718850)** en **Ori_atwotw (1057090)**.
- **Ori: Blind Forest** heeft géén bestand → al fusie-veilig.
- **Ori: WOTW** (**Ori_atwotw**): was een conflict-drager (=`1057090`, onbezeten);
  het bestand is op 2026‑09‑20 **geneutraliseerd** (→ `steam_appid.txt.disabled`)
  via de nieuwe tool `tools/steam-nonsteam-fix.sh` — voor de game inert
  (standalone pc-build, geen steam/emu-dlls), voor Steam geen fuseerbaar appid
  meer. De launcher voedt de appid al via env (`export STEAM_APPID=1057090`);
  Proton/ProtonFixes houdt daarmee z'n identiteit ("UNKNOWN (1057090)" in de
  eerste-run-log bevestigt dat de env-drager werkt). Terugzetten: de tool
  `restore`.
- "Het bestand weg ⇒ game start niet" is **niet** waar voor deze repacks; alleen
  echte Steamworks-licenties hebben het appid hard nodig, en die zitten hier niet.

**Gevolg voor de workflow:** de launcher-scripts hoeven niets op de Steam-route
te weten (zij draaien Proton direct, zonder de Steam-client-license-gate). De
Steam-shortcut-route incl. SteamInput/pad wordt **later bij de GUI** ingebouwd —
met als vuistregel: geen `steam_appid.txt` = veilig; aanwezig + niet bezeten =
Forza-patroon. Apart blijft de wrap-afhankelijkheid (exclusive-FS op
AMD/Wayland): díe bepaalt of een game óók zonder wrap via Steam zou stallen.

## Eigenaarschap & permissies

- Prefixen worden op lokale schijf aangemaakt → eigenaar is automatisch de
  gebruiker die de game start. Dit is bewust; het is de enige betrouwbare
  manier waarop Wine-prefixen correct werken.
- Scripts op de share: leesbaar voor de hele groep; uitvoerbaar maken met
  `chmod +x`.

## GUI-voornemen 

**De werking via de scripts is de basis; de GUI is de gebruikers vriendelijke manier.** 
Er is een Python-GUI die uitsluitend een **gebruiksvriendelijke
opstarthelper is**: een venster met een selector van spelletjes; bij kiezen wordt
het bijbehorende `game-launchers/LINUXLAUNCHERS/<game>.sh`-script aangeroepen (dat zelf de
prefix aanmaakt , en direct start).

**Zodra de prefix eenmaal is aangemaakt, heeft de gebruiker de GUI niet meer
nodig** — het `.desktop`-icoon (dat de scripts al automatisch aanmaken) start
de game direct met de lokale prefix, zonder terminal of GUI.

---

## Werklog / status (compaction-samenvatting)

> Opgeslagen als geheugen voor volgende sessies; hier staat waar het systeem
> mee bezig is, wat bewezen is en wat de volgende stappen zijn.

### Doel (lopend werk)

Cyberpunk 2077 is afgerond en gedocumenteerd (werklog hieronder); resultaat
bevestigd door gebruiker. Nieuwe spellen volgen hetzelfde patroon. Cities:
Skylines op AMD/Wayland is ook afgerond; daarbij werd de gamescope-wrap een
generieke core-optie (`GAME_GAMESCOPE` + `GAME_GAMESCOPE_RES`) in plaats van een
per-game hack.

### Nooit vergeten

- **Geen sudo / root** in de scripts; de gebruiker is de interactor en klikt
  zelf (kdialog/zenity) Ja of Nee. Overrides voor een latere GUI bestaan al:
  `WACOM_CHOICE=ja|nee`.
- **Geen backup-logica in de wacom-module** — backups doet de core
  (`_snapshot_backup` → `template-scripts/backup/`, ver1→ver3-rotatie).
  Debug-logs horen in `/tmp` (alleen voor de agent).
- **`tools/ask-yesno.sh`** is de herbruikbare Ja/Nee-vrager
  (TTY→kdialog→zenity→notify-send; exit 0=ja, 1=nee, 2=geen methode).
- **`disable_winebus`** (historisch: `Enable SDL=0` + `DisableHidraw=1`) maakte
  de toetsen ooit werkend, maar schakelde óók alle echte gamepads uit. De nu
  bewezen variant zet **alleen `Enable SDL=0`** (hidraw blijft aan) → toetsenbord
  werkt. Let op de nuance (gamepad-analyse, 2026-09): "better gamepads blijven
  werken via XInput/hidraw" geldt alleen zolang Wine die hint-route fysiek kan
  bereiken; op deze machine ontbreekt dat (geen hidraw-node voor de pad,
  `/dev/hidraw*` root-only), dus de pad speelt wél op OS-niveau, maar niet in
  XInput-only-games zoals Cyberpunk.
- **`WACOM_CHOICE` als env-var is NIET de bedoeling van de flow** — de knoop
  zelf moet bij elke start getoond worden, anders is de flow "niet zoals
  bedoeld".
- Bash-tool van de agent doodt achtergrondprocessen bij terugkeer (SIGHUP) →
  persistente runs via `setsid`/`nohup`. `pkill -f wine/proton` matcht de eigen
  shell → hang; zelf-matchende patronen vermijden of `-x` gebruiken.
- `_provision_fresh` wist een bestaande prefix niet zelf; voor een échte verse
  provision eerst `rm -rf ~/GAMEPREFIXES/<Game>`.
- **AMD/RADV + XWayland + DXVK exclusive-FS:** de game presenteert niet naar
  voren (zwart scherm, focus-stall) → **gamescope-wrap is de standaard-fix**
  (`GAME_GAMESCOPE=1`, optioneel `GAME_GAMESCOPE_RES` tegen het 720p-verlies).
  NVIDIA-machines hebben dit issue niet (bewezen op de GTX-1070-rij).

### Verifieerbare feiten

Met behulp van de Bevindingen<gamename>.md is vastgelegty hoe de launcher is gemaakt
Waar op gelet moet worden en andere cruciale bevindingen.

- **Hook-fasen in de core (2026-10-16):** `game-common.sh` dispatcht nu drie fasen:
  `PRE_PROVISION_HOOKS` (vóór `wineboot -i`), `PROVISION_HOOKS` (erna) en
  `PRE_LAUNCH_HOOKS` (elke start). Vóór deze datum bestond `PRE_PROVISION_HOOKS`
  **niet** in de core, terwijl `halopc.sh` en `colinmcrea4.sh` hem al gebruikten →
  de hook (`install_wine32`) draaide nooit. `_run_hook` houdt nu de hook-status
  vast (spinner stopt altijd, falende hook breekt af). Zie de launcher-README
  (`template-scripts/game-launchers/README.md`) voor de verificatie-`grep`.



### Relevante bestanden

```
template-scripts/game-core/game-common.sh        → core; PRE_LAUNCH_HOOKS gebouwd (idempotente drift-guards)
template-scripts/game-core/hooks/wacom-detect.sh → bewaard als herbruikbare interactieve module (niet meer voor Cyberpunk)
template-scripts/game-core/hooks/disable_winebus.sh → bewezen fix (Enable SDL=0, hidraw aan) — provision én pre-launch
template-scripts/game-core/hooks/install_vcrun2019.sh, install_gamescope.sh → provision hooks
template-scripts/game-launchers/cyberpunk2077.sh → dun launcher-script (v17)
template-scripts/game-launchers/citiesskylines.sh → GAME_GAMESCOPE=1; res auto-detect (xrandr) of pin via GAME_GAMESCOPE_RES
template-scripts/game-launchers/ori-willofthewisps.sh → v1, dun; IL2CPP pc-build standalone (oriandthewillofthewisps-pc.exe)
WINDOWSGAMES/Cities-Skylines-none-Steam/dxvk.conf → numCompilerThreads=4 + enableGraphicsPipelineLibrary=True (in de gamemap)
template-scripts/tools/ask-yesno.sh             → herbruikbare Ja/Nee-vrager
template-scripts/tools/pad-xinput-on.sh         → losse ROOT-tool: Xboxpad als echte XInput (xpad-weg + hidraw + udev-rule; `--shot`=tijdelijke chmod; `status`)
template-scripts/tools/pad-xinput-off.sh        → losse ROOT-tool: ongedaan maken (udev-rule weg + xpad terug); idempotent
template-scripts/tools/steam-nonsteam-fix.sh    → inspect/neutralise/restore/fake/scan/boom (conflict-dragers); toegepast op WOTW (1057090)
template-scripts/tools/appid.fromname.sh        → naam→appid (8 cijfers, `-l <len>`); cross-check met appid.numerator*.py
template-scripts/tools/steam-shortcut-cleanup.sh→ binair-VDF-shortcut-cleanup (list/verify/remove; --commit is dry-run-bewust)
backup/cyberpunk_gamepad.sh.sdl-route.20260920  → gearchiveerde SDL/winebus-route (doodlopend bewezen; vervangen door pad-xinput-*)
backup/gamepad.off.sh.sdl-sweep.20260920        → gearchiveerde SDL/marker-sweep (was niet wat gevraagd was; overbodig na pad-xinput-off)
template-scripts/tools/archive/                 → (overige vervallen tool-ingredienten)
~/GAMEPREFIXES/Cyberpunk2077/                   → lokale prefix (pfx/, compatdata/1091500/, .provisioned=17)
~/GAMEPREFIXES/OriWillOfTheWisps/               → lokale prefix (.provisioned=1), saves in AppData\LocalLow
~/GAMEPREFIXES/OriBlindForest/                  → lokale prefix (.provisioned=1); saves in AppData\Roaming\Steam\CODEX\261570\remote
```

