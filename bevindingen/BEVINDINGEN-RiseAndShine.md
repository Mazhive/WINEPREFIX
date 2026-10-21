# BEVINDINGEN — Rise & Shine (2017, native Linux)


Pad: `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Rise_and_Shine_Linux-ACTIVATED/Rise.and.Shine/`



## 1. Wat is het

| | |
|---|---|
| Titel | Rise & Shine (Steam-appid **347290**) |
| Developer / publisher | Super Mega Team / Adult Swim Games |
| Engine | **Unity 5.4.2f2** (b7e030c65c9b), Mono |
| Release | 2017-01-13 (Linux-build 2017-05-19); release hier: ACTiVATED, nfo-datum 2017-10-18 |
| Exe | **`RiseAndShine.x86_64`** — 25 935 472 B, ELF 64-bit LSB, interpreter `/lib64/ld-linux-x86-64.so.2`, stripped, BuildID `28ef31afbcbef824c9357629e7184f284c293a18` |
| Exe (32-bit) | `RiseAndShine.x86` — 25 656 464 B (niet nodig) |
| Data-map | `RiseAndShine_Data/` — 112 bestanden, 6,28 GiB |
| Bescherming | ACTiVATED Steam-emulator (`activated.ini` + vervangen `libsteam_api.so`) |

de exe heet `RiseAndShine.x86_64` 

## 2. Wat NIET het probleem is (afgevinkt, niet geraden)

| check | resultaat |
||---|
| `ldd RiseAndShine.x86_64` | **alle 18 dependencies resolven**, geen "not found" |
| NEEDED-lijst | `libdl, libpthread, librt, libGL, libX11, libXcursor, libXrandr, libstdc++, libm, libgcc_s, libc` — allemaal standaard |
| `ldd` op alle 3 plugins (`libCSteamworks.so`, `libsteam_api.so`, `ScreenSelector.so`) | **allen schoon**; `ScreenSelector.so` vraagt GTK2 (`libgtk-x11-2.0.so.0`) — aanwezig op deze machine |
| Uitvoerbit + eigenaar | `rwxrwxrwx`; mappen `2775 nfs:nfs`, peter zit in groep `nfs` → **schrijftest OK** in gamemap én Data-map |
| Data-mapnaam | `RiseAndShine_Data` klopt exact met Unity-regel (exe-naam minus `.x86_64` + `_Data`) |
| GPU/stuurprogramma | AMD Radeon RX 7600 XT, radeonsi, **Mesa 26.2.3-2**, OpenGL 4.6 Core Profile → geen issue |
| Audio | `AudioManager: Using PulseAudio: Default Output Device` |
| Mount | `nfs4 … soft,timeo=10,retrans=3` — zie risico §5.3 |
| In-game map beschikbaar voor schrijven | ja (peter ∈ groep `nfs`) |

## 3. Bewijs dat de game werkt

`~/.config/unity3d/Adult Swim Games/RiseAndShine/Player.log` (18 569 B, **2026-10-20 15:50**):

```
Initialize engine version: 5.4.2f2 (b7e030c65c9b)
Renderer: AMD Radeon RX 7600 XT (radeonsi, navi33, ACO, DRM 3.64, 7.1.7+deb14-amd64)
Version:  4.6 (Core Profile) Mesa 26.2.3-2
OPENGL LOG: Creating OpenGL 4.6 graphics device
AudioManager: Using PulseAudio: Default Output Device
- Completed reload, in  0.199 seconds
Using native desktop resolution 1920 x 1080
Setting up 4 worker threads for Enlighten.
Initialized data
```

Verder in `~/.config/unity3d/Adult Swim Games/RiseAndShine/prefs` — echte, verder
geschreden voortgang (niet een first-run-artefact):

```
<GameStarted=1>  <TutorialDone=1>  <FirstInitialization=1>
<C01-S01=1> <C01-S02=0> <C02-S01=0> … <C03-S01=0> …
<NumRespawns=31>  <NumStarsCollected=1>  <NumChestsOpened=1>
<Screenmanager Is Fullscreen mode=1>  1920 x 1080
```

**Dit bewijst twee dingen tegelijk:** de game draait verder dan de menu's, en **de
voortgang wordt lokaal opgeslagen** → Steam Cloud is niet nodig om te spelen.

Let op: de `Player.log` noemt het pad
`/mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/LINUX/Rise_and_Shine_Linux-ACTIVATED/...`
(dus de **andere** kopie, zie §5.2). De kopie in `Native/` is byte-identiek maar is
zelf nog niet gestart.

## 4. De twee bevestigde defects (alleen Steam)

De log bevat precies **één** foutmelding:

```
EntryPointNotFoundException: InitSafe
  at (wrapper managed-to-native) Steamworks.NativeMethods:SteamAPI_InitSafe ()
  at Steamworks.SteamAPI.Init () [0x00000]
  at SteamManager.Awake ()
```

### 4.1 Oorzaak A — `libCSteamworks.so` exporteert `InitSafe` niet  *(zekerheid: hoog)*

De managed kant staat in `Assembly-CSharp-firstpass.dll` (strings: `CSteamworks`,
`NativeMethods`, `InitSafe`, `SteamAPI_InitSafe`). Dat is de **CSteamworks-brug**, die
P/Invoke't naar `libCSteamworks.so` met een verkort symbool (`SteamAPI_Init` → `Init`).

`nm -D --defined-only libCSteamworks.so` (924 exports) — de enige Init-gerelateerde zijn:

```
Init
RunCallbacks
Shutdown
GameServer_Init
```

`nm -D … | grep -w InitSafe` → **leeg**. `strings -a … | grep -x InitSafe` → **leeg**.
Dus: managed code vraagt `InitSafe`, de native brug levert die niet → `EntryPointNotFoundException`.

De emulator-`libsteam_api.so` in dezelfde map exporteert `SteamAPI_InitSafe` wél (0x1bcdc),
maar daar gaat de managed code **niet** langs — die gaat via CSteamworks. Twee .so's,
twee verschillende symbolen; niet verwarren.

### 4.2 Oorzaak B — `activated.ini` staat niet waar de emulator hem zoekt  *(zekerheid: hoog)*

Reproductie (python ctypes, `dlopen` op de game-eigen .so), A/B in dezelfde sessie:

```
# B — situatie zoals nu in de gamemap (ini naast de EXE, niet naast de .so):
Internal error 0x01: Ini file not found at
  .../RiseAndShine_Data/Plugins/x86_64/activated.ini!

# A —ini náást libsteam_api.so (zelfde .so, niets anders veranderd):
SteamAPI_InitSafe()      -> True
SteamAPI_IsSteamRunning() -> True
```

De emulator lost het pad op via z'n **eigen** .so-locatie (`dladdr`), niet via cwd en
niet naast de executable. Nu staat `activated.ini` in `Rise.and.Shine/` (conform de nfo:
"Unpack, Run RiseAndShine.* from game dir") — de emulator kijkt in
`RiseAndShine_Data/Plugins/x86_64/`. Met de ini op de juiste plek is de emulator
**volledig werkend** (init én "steam running" = True).

### 4.3 Wat dit kost — en wat niet

| | |
|---|---|
| Keihard | Geen achievements, geen leaderboards, geen Steam Cloud |
| Bewijs | `~/.local/share/Steam/ACTiVATED/347290/{achievements,leaderboards}.ini` zijn elk **29 B** en sinds **2025-05-24** onaangeroerd |
| `activated.ini` | `DLCUnlockall=0` → DLC's ook niet vrij |
| **Niet** | Gameplay of opslaan: bewezen werkend via lokale `prefs` (§3) |

### 4.4 Volgorde van fixen

1. Eerst **B** (ini verplaatsen): dat is een copy, geen code, en meetbaar (§4.2-test wordt True).
2. Dan **A** opnieuw testen. Het is *denkbaar* dat CSteamworks na een werkende emulator
   alsnog `Init` gebruikt als fallback — dat is **niet** bewezen. Meet het, gok het niet.
3. Als A blijft staan: nievere `libCSteamworks.so` met `InitSafe`-export zoeken, of de
   Steam-laag accepteren als dood (speelbaar zoals aangetoond).

## 5. Opruimen / infrastructuur

### 5.1 Byte-identieke duplicaten ín `RiseAndShine_Data/` — 2,48 GiB

Unity leest alleen `resources.assets`, `resources.assets.resS` en `*.resource`. De rest
is dode ballast. Alle paren hieronder zijn **volledig geverifieerd identiek**
(`md5sum` voor het kleine paar, **volledige `cmp`** van 2,4 GB voor het grote paar):

| wegwerp-kandidaat | is kopie van | bytes |
|---|---|---|
| `Rise_and_Shine_Linux-ACTIVATED.ress` | `resources.assets.resS` | 2 410 398 416 |
| `Rise_and_Shine_Linux-ACTIVATED` | `resources.assets` (md5 `e122212f9a0e3121be765363fc4a91f0`) | 3 668 132 |
| `sharedassets12.assets.resS.xxx` | `sharedassets12.assets.resS` | 73 581 516 |
| `sharedassets4.assets.resS.hlp` | `sharedassets4.assets.resS` | 112 759 424 |
| `sharedassets10.assets.resS.hlp` | `sharedassets10.assets.resS` | 41 090 356 |
| `sharedassets9.assets.resS.xxx` | `sharedassets9.assets.resS` | 15 613 240 |
| `sharedassets24.assets.resS.xxx` | `sharedassets24.assets.resS` | 2 212 864 |
| `sharedassets0.assets.resS.txt` | `sharedassets0.assets.resS` | 480 000 |
| **totaal** | | **2 659 803 948 B ≈ 2,48 GiB** |

Aparte inodes (geen hardlinks). Verwijderen is in principe veilig, maar dit is een
**actie voor de beheerder, niet voor deze agent** — en doe het pas nadat de game een
keer uit `Native/` is gestart.

### 5.2 De hele game staat op de share — 6,4 G


- `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Rise_and_Shine_Linux-ACTIVATED` → **6,4 G**


### 5.3 NFS-risico: `soft`-mount op een 2,4 GB-texturebestand

`/mnt/VG_00/PUBLIC-LIBRARY` hangt met `nfs4 …,soft,fatal_neterrors=none,timeo=10,retrans=3`.
Bij een Netwerk-hapering geeft `soft` in plaats van te blokkeren een **EIO** terug. De
game streamt continu uit één 2,4 GB `resources.assets.resS` → een enkele EIO is een
stille, ogenschijnlijk willekeurige stall/crash. Dit is een **risico**, geen bewezen
oorzaak van een klacht — maar het is de eerste kandidaat als er ooit "sporadisch
vastlopen" gemeld wordt. Optie: `hard`-mount, of een lokale kopie.

### 5.4 Wat ontbreekt voor de GUI

- `template-scripts/game-launchers/LINUXLAUNCHERS/` bevat **geen** rise/shine-script
  (40 scripts, allen andere games).
- Geen icoon met een naam die matcht "rise and shine" in `gameicons/` (49 bestanden)
  of in `GAMEICONS/`. `scrape_icons/games_index.json` (140 entries) noemt de game ook niet —
  logisch: `SKIP_PLATFORM_DIRS = {"WINDOWS", "LINUX"}` slaat native Linux over.
- `~/.config/gamelauncher/settings.conf` bevat **geen** `ICONS_ROOT`-key
  (alleen `SOUND`, `SOUNDTRACK`, `SOUND_VOL`) → de GUI valt terug op de default
  `ICONS_ROOT_DEFAULT = /mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS`.

## 6. Icoonplan — bron, naam en juiste map

### 6.1 Waar het icoon moet komen (conventie geverifieerd in code)

Twee mappen, **beide** gevuld — ze zijn nu een spiegel van elkaar (zelfde md5, andere inodes;
gecontroleerd op `celeste.png`, `silence.png`, `downward.png`):

| # | pad | wie leest het |
|---|---|---|
| 1 | `/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/RiseAndShine.png` | GUI-carousel (`game-gui.py`, `ICONS_DIR`; `settings.conf` heeft geen `ICONS_ROOT` → default geldt) |
| 2 | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts/game-launchers/gameicons/RiseAndShine.png` | desktop-shortcut (`game-common.sh`, `local icons_dir="$base/game-launchers/gameicons"`) |

Formaat van de bestaande iconen: **1024×1024 RGBA PNG** (geverifieerd met PIL).

### 6.2 Naam — de matchregel is genormaliseerd

Zowel de GUI (`_norm`) als `game-common.sh` reduceren naam tot `tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'`:

- launcher-sleutel = bestandsnaam van het script zonder `.sh`
- `game-common.sh` normaliseert **`GAME_NAME`**
- GUI controleert eerst `GAME_ICON` uit het script, dan de genormaliseerde sleutel

Daarom deze **exacte** combinatie (alle drie de regels raken raak):

```
LINUXLAUNCHERS/riseandshine.sh        → key "riseandshine"
export GAME_NAME="RiseAndShine"       → genormaliseerd "riseandshine"
export GAME_ICON="RiseAndShine.png"
icoonbestand: RiseAndShine.png        → genormaliseerd "riseandshine"
```

Let op: `GAME_NAME="Rise & Shine"` normaliseert naar **`riseshine`** (zonder "and") — dat
matcht `RiseAndShine.png` **niet**. Gebruik dus `RiseAndShine` als `GAME_NAME` en zet
`GAME_DISPLAY_NAME="Rise & Shine"` voor de zichtbare naam.

### 6.3 Bronnen op internet — vandaag gecontroleerd (HTTP-status, geen download)

Steam CDN, appid **347290**, `cdn.cloudflare.steamstatic.com`:

| URL | status | bytes | type | oordeel |
|---|---|---|---|---|
| `…/steam/apps/347290/library_600x900_2x.jpg` | **200** | 191 914 | image/jpeg (1200×1800 portret) | **aanbevolen bron** |
| `…/steam/apps/347290/library_600x900.jpg` | **200** | 66 386 | image/jpeg | fallback, lage resolutie |
| `…/steam/apps/347290/header.jpg` | **200** | 65 481 | image/jpeg (460×215) | slecht voor vierkant |
| `…/steam/apps/347290/capsule_616x353.jpg` | **200** | 119 113 | image/jpeg | landscape, niet geschikt |
| `…/steam/apps/347290/logo.png` | **200** | 48 574 | image/png | alleen transparant logo, **geen icoon** |
| `…/steam/apps/347290/icon.ico` | **404** | — | — | **bestaat niet** |

Alternatief met echte 1:1 art: **SteamGridDB** (filters "1:1 – Square, 1024x1024") — maar
de API geeft **401** zonder key; die hoort in `scrape_icons/.env` als
`STEAMGRIDDB_API_KEY`. Let op: de eigen `scrape_icons`-pipeline haalt deze game **nooit
vanzelf op**, want `SKIP_PLATFORM_DIRS` bevat `LINUX`.

### 6.4 Omzetting naar 1024×1024 RGBA (ImageMagick + PIL aanwezig)

Gereedschap aanwezig: `/usr/bin/convert`, `/usr/bin/magick`, PIL 12.3.0. Voorstel:
vierkante center-crop met zachte vervaging eronder, zodat het portret vol blijft.

```bash
SRC=https://cdn.cloudflare.steamstatic.com/steam/apps/347290/library_600x900_2x.jpg
TMP=/tmp/opencode/riseandshine
mkdir -p "$TMP"
curl -fsSL "$SRC" -o "$TMP/src.jpg"

magick "$TMP/src.jpg" -resize 1024x1024^ -gravity center -extent 1024x1024 \
       \( "$TMP/src.jpg" -resize 1024x1024 -blur 0x24 -brightness-rectangle 1024x1024 \) \
       -gravity center -composite -alpha on -channel A -evaluate set 100% \
       PNG32:"$TMP/RiseAndShine.png"
```

Plaatsen (beide mappen, zelfde bestand):

```bash
D1=/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS
D2=/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts/game-launchers/gameicons
cp "$TMP/RiseAndShine.png" "$D1/RiseAndShine.png"
cp "$TMP/RiseAndShine.png" "$D2/RiseAndShine.png"
```

Verificatie:

```bash
identify -format '%wx%h %[channels]\n' "$D1/RiseAndShine.png" "$D2/RiseAndShine.png"
# verwacht twee keer: 1024x1024 srgba
```

### 6.5 Dit plan is NIET uitgevoerd

Regel van deze agent: uitsluitend naar `BEVINDINGEN-<GameName>.md` wegschrijven,
**nooit** launchers of `.sh` schrijven. Er is dus **niets** gedownload, **niets** geplaatst
en **geen** launcher aangemaakt. §6 is de overdracht aan de Launcher-Builder /
beeldbeheerder.

## 7. Actieplan voor de Launcher-Builder

1. **Eerst padkeuze vastleggen** (§5.2): productie wordt `Native/Rise_and_Shine_Linux-ACTIVATED`.
   De GAMES-kopie laten staan tot de launcher bewezen werkt, daarna pas opruimen.
2. **Icoon plaatsen** volgens §6 (beide mappen, `RiseAndShine.png`).
3. **Launcher** `template-scripts/game-launchers/LINUXLAUNCHERS/riseandshine.sh`. Dit is
   een **directe ELF-binary**, dus net als `downward.sh`: `GAME_NATIVE_SHELL` **niet**
   zetten. `GAME_NATIVE_CMD="RiseAndShine.x86_64"` (zonder pad → relatief t.o.v. cwd = `GAME_DIR`).

   Boilerplate-velden (referentie: `celeste.sh`, `downward.sh`, `game-common.sh`):

   ```bash
   export GAME_NAME="RiseAndShine"
   export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/Native/Rise_and_Shine_Linux-ACTIVATED/Rise.and.Shine"
   export GAME_NATIVE="1"
   export GAME_NATIVE_CMD="RiseAndShine.x86_64"
   export GAME_LAUNCHER="$(readlink -f "$0")"
   export GAME_DISPLAY_NAME="Rise & Shine"
   export GAME_ICON="RiseAndShine.png"
   export CREATE_DESKTOP_SHORTCUT="1"
   source "$(dirname "${BASH_SOURCE[0]}")/../../game-core/game-common.sh"
   game_main "$@"
   ```

4. **Steam-fix (optioneel, laag risico):** kopieer `activated.ini` náást
   `RiseAndShine_Data/Plugins/x86_64/libsteam_api.so` (en voor de compleetheid ook in
   `Plugins/x86/`). Verwijder de originelen **niet** — kopiëren. Test daarna of
   `EntryPointNotFoundException: InitSafe` verdwenen is uit de verse `Player.log`
   (§4.4). Blijft de melding staan, dan is oorzaak A (§4.1) de rem en is de game
   alsnog speelbaar.
5. **Niet vergeten:** de juiste spelling is `RiseAndShine.x86_64` (§1).
6. **Optional, na een eerste succesvolle run vanuit `Native/`:** de 2,48 GiB duplicaten
   uit §5.1 verwijderen (pas ná die run, zodat je zeker weet dat de game het zonder ze doet).

## 8. Overdracht

Analyse afgerond, bewijs compleet en herleidbaar. Dit document is de enige output van de
Diagnostiek-Agent. Doorverwijzen naar de **Launcher-Builder Agent** (launcher + icoon) en,
los daarvan, naar de **beheerder** voor de padkeuze en het duplicate-opschonen (§5).

---

## 9. Uitvoeringsverslag — Launcher-Builder (2026-10-20)

Uitvoering van §7. Alles hieronder is **gedaan en geverifieerd**; §5.1 (2,48 GiB
duplicaten) is **bewust niet** aangeraakt — dat blijft een actie voor de beheerder.

### 9.1 Uitgevoerd

| # | actie | resultaat |
|---|---|---|
| 1 | Launcher `LINUXLAUNCHERS/riseandshine.sh` | aangemaakt, `bash -n` OK; `GAME_NATIVE="1"`, `GAME_NATIVE_CMD="RiseAndShine.x86_64"` (relatief), **geen** `GAME_NATIVE_SHELL` |
| 2 | Icoon `RiseAndShine.png` | in **beide** mappen, zelfde md5 `cb3dd553965e72a60dfa7023b50b731d`, 1024×1024 RGBA (§6.1/§6.4) |
| 3 | `activated.ini` gekopieerd | → `Plugins/x86_64/` én `Plugins/x86/`; originelen ongewijzigd (md5 `a84f5817…` identiek aan brond) |
| 4 | Desktop-shortcuts | `~/Desktop/RiseAndShine.desktop` + `…-instellingen.desktop`, `desktop-file-validate` clean, icoon gekoppeld |

**Icoon-herkomst** (afwijking op §6.3): de `library_600x900_2x.jpg` wordt door de
Steam-CDN feitelijk als **600×900** geleverd (191 914 B), niet 1200×1800. Omzetting
is contain (volledig portret zichtbaar, dus géén afgekapt logo) bovenop een geblurde
vierkante achtergrond → `PNG32` 1024×1024, volledig dekkend (alpha overal 255).
SteamGridDB bleef buiten beschouwing (401 zonder key).

### 9.2 Getest (bewijs)

- **Launch**: `cd` naar `GAME_DIR` vóór de start → `Set current directory to …/Rise.and.Shine`,
  `Found path: …/RiseAndShine.x86_64`, engine + data geïniseerd, `prefs` weggeschreven (18:03).
- **GUI**: `scan_games()` → het spel staat in de carousel, `display_name = "Rise & Shine"`,
  `is_native = True`, `GAME_ICON = RiseAndShine.png` → opgelost pad in `GAMEICONS/`,
  pixmap 1024×1024. `settings.conf` heeft geen `ICONS_ROOT` → default geldt (§5.4).
- **Fix B gemeten** (python ctypes op de game-eigen `.so`, A/B in dezelfde sessie):
  zonder ini → `Internal error 0x01: Ini file not found`; mét ini →
  `SteamAPI_InitSafe() = True`, `SteamAPI_IsSteamRunning() = True`.
  Bewijs dat de emulator werkt zodra de managed kant erbij kan (§4.4-stap 1 = klaar).
- **Fix A blijft staan**: verse `Player.log` bevat nog exact dezelfde
  `EntryPointNotFoundException: InitSafe` (regels 99–101), géén tweede foutmelding.

### 9.3 NIEUW: SEGFAULT bij afsluiten (pre-existing)

Beide runs eindigen met SIGSEGV **in de exit-handler van de emulator**:

```
#0  libsteam_api.so + 0x1be39   mov 0x18(%rbx),%rsi   (rbx ongeldig → SEGV_MAPERR)
#1  __run_exit_handlers (libc)      #2  __GI_exit
```

- Het adres `0x1be39` ligt in de code-span van `SteamAPI_RunCallbacks` (0x1bdae–0x1bfb9),
  in een niet-geëxporteerde interne helper.
- **Bewijs van pre-existing**: `coredumpctl` toont twee dumps met **byte-identieke
  backtrace** — 15:50:49 (PID 1809535, **GAMES-kopie, vóór alle wijzigingen**) en
  18:03:48 (PID 1877755, Native + fix B). Zelfde offset, zelfde keten.
- Getriggerd door een **normale quit via het menu** (gemeld door de gebruiker), dus bij
  élke sluiting. Reproduceert niet in een losse ctypes-harness (laden/Init/exit = exit 0);
  het spel roept zelf meer aan (CSteamworks `NEEDED libsteam_api.so`).
- **Gevolg**: `set -e` in de launcher → exit **139** → `game-gui.py:860` toont
  `QMessageBox "Game start mislukt"` bij elke sluiting.
- **Besluit (gebruiker, 2026-10-20)**: launcher vangt **alleen 139** op en geeft 0 terug;
  alle andere exit-codes blijven doorlopen. Getest met nagebouwd patroon:
  segv-kind → 0, rc=1 → 1, rc=127 → 127, rc=0 → 0.

### 9.4 Openstaand

1. **Beheerder — duplicaten (§5.1)**: er is nu een bewezen run vanuit `Native/`; de
   2,48 GiB mogen weg. Deze agent heeft ze **niet** verwijderd.
2. **Padkeuze (§5.2)**: launcher pointert naar `Native/…`; de GAMES-kopie staat er nog.
3. **Fix A (optioneel)**: nievere `libCSteamworks.so` met `InitSafe`-export, óf de
   Steam-laag als dood accepteren (gameplay + lokale save zijn bewezen; achievements /
   cloud / DLC blijven uit — §4.3).
