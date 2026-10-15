# BEVINDINGEN — StarBorne

> ⚠️ **BELANGRIJK: ONLINE-ONLY GAME — BACKEND PERMANENT OFFLINE (SINDS ~2022)**
> 
> StarBorne is een **online-only** Unity-strategiespel (Solid Clouds / UpSoft PatchKit).
> De auth/backend servers (`auth-live.starborne.com`, `sba.starborne.com`) **bestaan niet meer**
> (DNS lost niet op). Zonder werkende backend → **geen login-token → geen spel**.
> 
> **Dit is niet op te lossen met launcher, prefix, hooks of Wine-instellingen.**
> Enige manier om te spelen: een **private/offline server** draaien (buiten scope van dit project).
> 
> → **Voor productiegebruik: uitsluiten/skippen.** Launcher-script (`starborne.sh` v2) staat
> technisch correct voor het geval er ooit een private server beschikbaar komt.

Diagnostiek-Agent, read-only analyse. Datum: 2026-10-11.
Methode: aftrekkende werkwijze uit `WERKWIJZE.md`. Er is **niets** gewijzigd aan
game-bestanden, prefixen of scripts; alleen gelezen.

## 0. Opdracht & inputs

| Rol | Pad |
|---|---|
| Game (executables) | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/StarBorne` |
| Referentie-prefix (meetlat, **read-only**) | `/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/movedprefixes/StarBorne` |
| Productie-prefix | bestaat op dit moment niet (`~/GAMEPREFIXES/` is leeg) |

StarBorne is een **online-only** Unity-strategiespel van Solid Clouds (Iceland),
uitgebracht/gedraaid rond 2019–2022. Er is geen Steam-AppID; het is een standalone
UpSoft/PatchKit-release.

---

## 1. Samenvatting (TL;DR)

1. **Blocker (hoog vertrouwen):** de online backend van het spel is verdwenen.
   `auth-live.starborne.com` en `sba.starborne.com` lossen **niet meer op in DNS**;
   `api2.patchkit.net` leeft nog maar de game-API/auth niet. Zonder login-token kan de
   client niet starten. Dit is een **externe oorzaak**, niet met een prefix/launcher te
   repareren.
2. **Interne fout (middel vertrouwen):** in de laatste echte run probeert de client bij
   het verlaten van een match (`GameStateManager.LeaveGame`) via `Process.Start(...)`
   de launcher te herstarten; Wine gooit `Win32Exception (0x80004005): Path not found`.
   Dat is een pad-/werkmap-probleem in Wine's `ShellExecuteEx`, wél prefix-fixeerbaar.
3. **Historische crash (middel/laag vertrouwen):** de patcher (`StarbornePatcher.exe`)
   crashte op 2020-09-05 zesmaal **identiek** in `UnityPlayer.dll`
   (`called a function with an invalid parameter at 0033:805b220e`). Dit is één
   reproduceerbare bug (zelfde fault-adres), geen willekeurige crash.
4. **Niet de oorzaak (bewezen):** de "native VC++ runtimes" in de referentie-prefix zijn
   in werkelijkheid **Wine placeholder DLL's** (`"Wine placeholder DLL"`), geen echte
   Microsoft-runtimes. De `DllOverrides native,builtin` zijn dus in de praktijk no-ops.
   Native VC++ installeren is **niet** aangetoond als de oplossing.

---

## 2. Architectuur & uitvoerbare bestanden

Alles is **PE32+ / x86-64** (`file`):

```
Launcher.exe                      (root)   PE32+ x86-64, Qt/UpSoft/PatchKit-launcher
app/StarborneLauncher.exe                  PE32+ x86-64, de "hub" (Unity)
patcher/StarbornePatcher.exe               PE32+ x86-64, Unity 2018.4.10f1
starborne-live/Starborne.exe               PE32+ x86-64, Unity 2019.4.10f1
starborne-dissidence-live/Starborne.exe    PE32+ x86-64
starborne-sovereign-space-live/Starborne.exe PE32+ x86-64   <- in de 2022-logs gebruikt
```

Start-keten:

```
Launcher.exe  --(patchkit.net)-->  patcher/StarbornePatcher.exe
              --installeert/patched-->  app/StarborneLauncher.exe   (hub, login)
              --launcht map-client-->   starborne-<map>-live/Starborne.exe
                                        (args: --refreshToken --gameId --role
                                               --globalId --mapName -logFile)
```

Evidence in `Launcher.exe`-strings: `UpSoft`, `Solid Clouds ehf.0/1`, `launcher_path`,
`PatchKit`-URL's. In `patcher/.../Assembly-CSharp.dll`: `ExecuteLauncher`,
`FindLauncherExecutable`, `GetDefaultLauncherName`, `GetLauncherProcessStartInfo`,
`LauncherPathFileName`, `LauncherRelay`, `NonLauncherExecution`.
=> de game gebruikt **`Process.Start`** om zuster-exes te vinden/herstarten.

Register dat de launcher gebruikt (in de referentie-prefix):

```
[Software\Solid Clouds\StarborneLauncher]                      (Unity PlayerPrefs: resolutie e.d.)
[Software\UpSoft\ed6557e211c93919d637b61e7278fbcflauncher-]
    "patcher_secret"="77a839cff48f76c627e552173b3b4cdf"        (PatchKit app-id / secret)
```

---

## 3. Log-inventaris (waar staat wat)

| Bestand | Datum | Inhoud |
|---|---|---|
| `StarBorne/launcher-log.txt` | 2020-09-05 t/m 2022-04-20 | UpSoft launcher; toont D:/ pad → later Z:/ pad |
| `StarBorne/Logs/Gravity #3/Client_2022-04-20.22-42-47.log` | 2022-04-20 | map-client, 8003 regels |
| `StarBorne/Logs/Gravity #3/Client_2022-04-20.22-53-57.log` | 2022-04-20 | map-client, 7350 regels |
| `StarBorne/app/StarborneLauncher_dxgi.log`, `*_d3d11.log` | 2022 | DXVK v1.10.1 |
| `StarBorne/patcher/StarbornePatcher_d3d11.log` | 2020 | DXVK v1.7-8 |
| `movedprefixes/StarBorne/drive_c/users/peter/Temp/Solid Clouds/StarbornePatcher/Crashes/Crash_2020-09-05_*/error.log` | 2020-09-05 | **6 crashdumps** van de patcher |

Let op: **`movedprefixes/StarBorne` bevat nog de crashdumps van 2020-09-05** en is
ná die dag niet meer aangeraakt (geen bestanden nieuwer dan 2020-09-06). Het is dus
een **momentopname van de crashende sessie**, niet bewezen een werkende meetlat.
De 2022-client-logs staan in de *game-map* (NFS), niet in deze prefix — die zijn met
een andere (inmiddels verdwenen) prefix gemaakt.

---

## 4. Gemeten crashsignaturen

### 4.1 Patcher-crash 2020-09-05 — 6× identiek (fault-adres bevestigd)

Uit alle zes `error.log`s exact hetzelfde:

```
StarbornePatcher by Solid Clouds [version: Unity 2018.4.10f1_a0470569e97b]
UnityPlayer.dll called a function with an invalid parameter in module UnityPlayer.dll at 0033:805b220e.
...run by steamuser.
RIP: 0x00000001805b220e   RBP: 0x0000000000000000   SegCs: 0x0000000000000033
RDI: 0  RSI: 0  RBX: 0
```

Tijden: 14:58:01, 15:04:04, 15:06:20, 15:12:38, 15:13:22, 15:15:34 — alle zes na een
launcher-run, allemaal dezelfde module-offset. **Eén bug, reproduceerbaar** (WERKWIJZE
valkuil #2: vergelijk het adres, niet alleen "er was een crash").

Module-relatief adres: `UnityPlayer.dll+0x5B220E`. De dump geeft geen API-naam; het is
Unity's `EXCEPTION_INVALID_PARAMETER`-pad (een WinAPI die `ERROR_INVALID_PARAMETER`
teruggaf). De code op EIP (`48 8d 8c 24 10 05 00 00 ba 09 00 00 00`) zet een
stack-buffer + lengte 9 klaar ⇒ vermoedelijk een call met een 9-teken string
(niet te bewijzen uit de dump alleen).

### 4.2 Client 2022-04-20 — `Launching Client` → `Path not found` (2× identiek)

Beide client-logs eindigen identiek:

```
[21/04/2022 ... ] Launching Client
System.ComponentModel.Win32Exception (0x80004005): Path not found.
  at System.Diagnostics.Process.StartWithShellExecuteEx(...)
  at System.Diagnostics.Process.Start(...)
  at Assets.Code.GameStateManagement.GameStateManager+<LeaveGame>d__10.MoveNext()
```

Dit is de client die bij **`LeaveGame`** (terug naar de hub na een match) een executable
wil herstarten via `Process.Start` en daarbij Wine's shell laat falen. De game draait dus
wél: D3D11-device aangemaakt, verbinding met `sba.starborne.com`/`auth-live...` gelukt,
map `Gravity` geladen — en **pas bij het verlaten** gaat het mis.

### 4.3 Gedeelde managed fout (beide 2022-logs)

```
NullReferenceException at UI_PanelManager.LoadScenePanels / UnloadScenePanels (UI_ScenePanels)
"The referenced script on this Behaviour (Game Object 'sphere_Large/Small') is missing!"
```

Dit is een **game-side .NET/asset-bundle-fout** (ontbrekende scripts), geen Wine-crash.
Vermoedelijk horen deze bij een (deels) gemiste/gedeeltelijke patchronde; het spel draait
er in de praktijk doorheen.

---

## 5. Meting referentie-prefix (meetlat)

| Eigenschap | Waarde |
|---|---|
| Architectuur | `#arch=win64` |
| Windows-versie | Microsoft Windows **7**, SP1, build **7601**, CurrentVersion 6.1 |
| Aangemaakt / laatste wijziging | 2020-09-05 (`.update-timestamp=1591827864`) |
| Users | `peter` **én** `steamuser` (dus zowel plain-wine als Proton gebruikt) |
| dosdevices | alleen `c:` → drive_c, `z:` → `/`, plus com1..4. **Geen `d:`** |
| `winetricks.log` | **afwezig** (geen winetricks-verbs gelogd) |

### DllOverrides (uitlezen ≠ oorzaak)

```
[Software\Wine\DllOverrides]
  api-ms-win-crt-* = native,builtin
  atl100/110/120/140, concrt140, msvcp100/110/120/140,
  msvcr100/110/120/140, ucrtbase, vcomp*, vcruntime140 = native,builtin
  winemenubuilder.exe = ""
[Software\Wine\Direct3D]  OffscreenRenderingMode=fbo
```

**Cruciaal:** de DLL's die hierbij horen in `system32`/`syswow64` zijn géén echte
Microsoft-runtimes maar Wine-placeholders:

```
msvcp140.dll   -> "Wine placeholder DLL"
vcruntime140.dll -> "Wine placeholder DLL" (4616 bytes)
ucrtbase.dll   -> "Wine placeholder DLL"
d3dcompiler_47.dll -> "Wine placeholder DLL" (4556 bytes)
```

Omdat `native` ontbreekt valt Wine terug op `builtin`. De overrides zijn dus
**functioneel no-ops**. Ter vergelijking: `movedprefixes/haloinfinite` heeft een
**lege** DllOverrides en werkt ook — de overrides zijn niet wat StarBorne onderscheidt.

### Geen pad-/installatie-afhankelijkheid in het register

`grep` op `D:\`, `D:/StarBorne` in `system.reg`/`user.reg` geeft **niets**. Het spel
heeft dus (anders dan CMR4) geen installatiepad-sleutel nodig om te starten.

---

## 6. Root-cause analyse (met vertrouwen)

### A. Online backend verdwenen — **HOOG** (externe blocker)

```
api2.patchkit.net        -> 99.84.252.68   HTTP 403 (leeft, CDN/API-root)
auth-live.starborne.com  -> GEEN DNS
sba.starborne.com        -> GEEN DNS
starborne.com            -> 216.150.1.1    (geparkeerd)
```

De client doet `POST https://auth-live.starborne.com/connect/token` en verbindt met
`sba.starborne.com`. Beide hosts bestaan niet meer. Zonder token kan `Starborne.exe`
niet starten en kan de hub niet naar een match. **Dit is niet op te lossen met een
prefix, hook of launcher** — alleen met een (bestaande) private/offline server, wat
buiten de scope van dit project valt.

### B. `Process.Start` → `Path not found` — **MIDDEL** (prefix/launcher-fixeerbaar)

`GameStateManager.LeaveGame` → `Process.Start(fileName)` → `ShellExecuteEx`.
Wine's shell kan de doel-exe niet vinden. Typische oorzaken:
- `UseShellExecute=true` met een **relatieve/bare bestandsnaam** (`Launcher.exe`,
  `../Launcher.exe`) of een Windows-pad dat niet bestaat; Wine zoekt dan in `PATH`
  en de **huidige werkmap**, niet naast de aanroeper.
- De aanroep gebeurt met de verkeerde CWD (Wine start de game vanuit de prefix,
  niet vanuit de game-root).

Fix-richting (niet uitvoeren door mij): start de game altijd met **CWD = game-root**
(`StarBorne/`), zodat `Launcher.exe` en `patcher/launcher_path` (`../Launcher.exe`)
resolveren. Dit is exact wat de boilerplate via `game-common.sh` hoort te doen.

### C. Patcher-crash `UnityPlayer.dll+0x5B220E` — **MIDDEL/LAAG**

Eén reproduceerbare Unity 2018.4-crash bij het opstarten van de patcher onder
(Proton-)Wine. De dump noemt geen API. Verklaringen die passen bij een vroege
Unity-startup onder Wine: display/monitor-enumeratie, DPI/thread-description, of
een WinAPI die op een NFS/`Z:`-pad `ERROR_INVALID_PARAMETER` teruggeeft. **Niet
bewezen** — daarom als hypothese, niet als conclusie (WERKWIJZE valkuil #5).

Belangrijk: de 2022-client draaide **wel**, dus deze patcher-crash was in 2022
kennelijk niet meer blokkerend (andere runner/prefix). Hij is dus een historisch
symptoom, niet automatisch de huidige blocker.

---

## 7. Wat NIET de oorzaak is

- **Native VC++ runtimes ontbreken** — ONWAAR: de aanwezige DLL's zijn Wine-placeholders,
  en `haloinfinite` werkt met een lege DllOverrides. (Valkuil #5: een aantrekkelijke
  maar onjuiste aanname.)
- **DllOverrides `Bayonetta.exe` / `NewColossus_x64vk.exe`** in de prefix — horen bij
  andere games, irrelevant voor StarBorne.
- **`VideoMemorySize` / GPU-spoof** — niet aanwezig/gevonden; DXVK-log toont een
  NvAPI-workaround ("reporting AMD GPU") maar dat is renderer-cosmetiek, geen crash.
- **Lokale D3D/DXVK-DLL's in de game-map** — er staan er **geen**; de renderer komt
  volledig uit prefix/Proton. Er valt dus niets te "vervangen" in de game-map.
- **Hoofdletterongevoeligheid / D:-schijf** — geen D:-referenties in het register; geen
  dubbel gespelde game-sleutels gevonden.
- **De NullReferenceException / "referenced script ... is missing"** — game-side
  managed bug, niet Wine; het spel bereikte er de map mee.

---

## 8. Premisse-check — wat ik nog van de gebruiker nodig heb

WERKWIJZE stap 1 ("Controleer de premisse") is **niet vervulbaar met de huidige
informatie**: er is geen verse productie-prefix, en de meegegeven prefix bevat alleen
2020-patcher-crashes. Ik heb dus **geen werkende-vs-crashende vergelijking** kunnen maken.
Om dit af te maken, graag één van:

1. **Het exacte huidige symptoom**: welke exe start je (`Launcher.exe` /
   `app/StarborneLauncher.exe` / `starborne-*-live/Starborne.exe`), welke foutmelding,
   en het volledige console-/Wine-log van die run.
2. **Bevestiging of een verse prefix überhaupt al getest is** (en zo ja: welk
   fault-adres/log). Zonder reproduceerbare crash heeft de rest van het aftrekken
   geen zin.
3. **Is een private/offline server beschikbaar?** Zo niet, dan is de game
   fundamenteel niet meer startbaar (oorzaak A) en is verder prefix-werk zinloos.

---

## 9. Actieplan voor de Launcher-Builder (beschrijvend — ik schrijf géén .sh)

> Uitvoering hoort bij de **Launcher-Builder Agent**. Onderstaande is het plan; ik
> heb geen scripts aangemaakt of gewijzigd.

### 9.1 Basis (alleen als er een werkende/offline login-route is)

- **GAME_EXE = `Launcher.exe`** (root). De rest van de keten start de launcher zelf.
  (Alternatief: `app/StarborneLauncher.exe` voor de hub, maar die heeft een
  refreshToken nodig die normaal via de launcher komt.)
- **`export PREFIX_ARCH="win64"`**, `SCRIPT_VERSION`, desktop-shortcut aan — conform
  boilerplate.
- **CWD = game-root** (`.../WINDOWSGAMES/StarBorne`) bij de launch. Dit adresseert
  oorzaak B (`Process.Start`/`launcher_path` resolutie). Verifieer dat `game-common.sh`
  de game met deze CWD start; anders is dat de eerste fix.

### 9.2 Hooks (voorstel, pas na bevestiging)

- **Geen** `install_vcrun*`-hook op basis van deze analyse: de referentie-prefix
  heeft geen échte native runtimes en `haloinfinite` werkt zonder. Niet toevoegen
  zonder test (valkuil #5).
- **`install_gamescope` / `disable_winebus`**: alleen overwegen bij concrete
  Wayland/fullscreen- of inputklachten; niet preventief.
- **Registry**: `[Software\UpSoft\...launcher-]` en `[Software\Solid Clouds\..]`
  worden door de launcher zelf aangemaakt; geen pre-launch hook nodig tenzij een
  test aantoont dat een verse prefix de `patcher_secret` mist en de launcher dat niet
  herstelt.

### 9.3 Runner

- Gebruik **GE-Proton** (zoals de 2022-run, DXVK v1.10.x) i.p.v. plain wine; de
  patcher-crash (oorzaak C) trad op in een `steamuser`/Proton-omgeving, dus test
  Proton expliciet tegen plain wine — één variabele per run.

---

## 10. Aanbevolen testvolgorde (aftrekkend, één variabele per run)

1. **Meet:** maak een **read-only** telling/vergelijking van de referentie-prefix
   (bestandsaantal, registergroottes) — referentie **niet** wijzigen.
2. **Premisse:** draai in een **aparte `diag-work`** (kopie, `rsync -a --delete`;
   nooit de bron) de gekozen exe met de referentie-prefix en leg het **fault-adres**
   vast. Vergelijk met `UnityPlayer.dll+0x5B220E` uit 4.1.
3. **Login-route eerst:** bevestig of de API/auth bereikbaar is (nu: **nee**). Zolang
   dat nee is, stopt elke poging hier — documenteer en stop.
4. **Alleen bij een reproduceerbare crash ná login:** ga differentiëren — begin met
   de CWD-fix (oorzaak B), daarna (indien nodig) runner (Proton vs wine), daarna
   pas register/DLL-groepen. Gebruik de **leave-one-in**-variant (WERKWIJZE valkuil #3):
   zet alles op de werkende referentie behalve één tak om de schuldige tak te vinden.
5. **Leg vast** vóór `movedprefixes/` verdwijnt.

---

## 11. Randvoorwaarden / terugrol

- Er is **niets gewijzigd**; er valt niets terug te rollen.
- `movedprefixes/StarBorne` en `StarBorne (copy)` blijven onaangeroerd (read-only).
- Een productie-prefix hoort in `~/GAMEPREFIXES/StarBorne/` te komen (nu leeg),
  vers via `wineboot -i`; nooit een bestaande prefix kopiëren.
- **Belangrijkste risico:** als oorzaak A (dode online backend) klopt, is StarBorne
  niet meer startbaar en moet dat expliciet aan de gebruiker worden gemeld voordat
  er launcher-werk in wordt gestoken.
