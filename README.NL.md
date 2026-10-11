# Wineprefix Templates for Shared Games

Een modulair, lichtgewicht script- en GUI-systeem voor Linux-omgevingen, ontworpen om gedeelde Windows-games af te spelen vanaf een centrale Network File System (NFS) share met geïsoleerde, lokale Wine-prefixen per gebruiker.

---

## 🚀 Overzicht

Het direct draaien van Windows-games vanaf een NFS-share door meerdere gebruikers veroorzaakt vaak bestandsslot-conflicten (*file locking*) en permissieproblemen in de Wine-prefix. 

Dit project lost dat op via een **hybride architectuur**:
* **Game-bestanden** staan centraal op de NFS-share (read-only voor spelers).
* **Wine-prefixen** worden voor elke gebruiker lokaal en **vers** aangemaakt in `~/GAMEPREFIXES/<Game>/`.
* **Modulaire Launchers:** Scripts op de share bevatten de opstartlogica. Ze werken volledig zelfstandig via de terminal óf via de meegeleverde PySide6 GUI (`game-gui.py`).

---

## 🏗️ Architectuur & Mapstructuur

```
NFS Share (Gedeeld, Read-Only/Read-Mostly)
└─ PRE-INSTALLED-GAMES/
   ├─ WINDOWSGAMES/<Game>/        # De originele game-bestanden (exes, assets)
   └─ WINEPREFIX/
      ├─ game-gui.py              # PySide6 Graphical Interface
      └─ template-scripts/
         ├─ game-core/
         │  ├─ game-common.sh     # Herbruikbare core (provisioning, launching, desktop-icoon)
         │  └─ hooks/             # Modulaire hooks (VC++ redists, winebus tweaks, gamescope)
         ├─ game-launchers/
         │  ├─ LINUXLAUNCHERS/    # Snelkoppelingen naar actieve launcher-scripts (*.sh)
         │  │  └─ gameicons/      # Afbeeldingen en icons voor de GUI
         │  ├─ angry-birds.sh     # Dun launcher-script (vanilla Wine)
         │  ├─ cyberpunk2077.sh   # Launcher met GE-Proton + VC++ Hooks
         │  └─ citiesskylines.sh  # Launcher met Proton + Gamescope-wrap
         └─ tools/
            ├─ install-proton.sh  # Automatische GE-Proton installer
            ├─ ask-yesno.sh       # Herbruikbare TTY/GUI vragen-helper
            └─ gamepad-status.sh  # Helper voor gamepad-diagnostiek

Lokaal (Per Gebruiker op de eigen PC)
└─ ~/GAMEPREFIXES/
   └─ <Game>/
      ├─ pfx/                    # Lokale Wine-prefix (eigendom van de speler)
      ├─ compatdata/<appid>/     # Proton compatibiliteitsmap (symlink)
      └─ .provisioned            # Versie-marker voor automatische updates
```

---

## 🔑 Key Features

* **Geïsoleerde Executie:** Geen slot-conflicten op het netwerk. Elke speler heeft z'n eigen lokale prefix en instellingen.
* **PySide6 Graphical Interface (`game-gui.py`):**
  * **Interactieve Cover-roller:** Blader visueel door beschikbare games met custom icons en automatische fallback-placeholders.
  * **Live Terminal Log Streaming:** Bekijk direct de `stdout`/`stderr` van de game en launchers via `QProcess`.
  * **Schakelopties voor Startparameters:** Eenvoudig vinkjes zetten voor Desktop-shortcuts, Gamescope-wrapping, SDL3-fallbacks, Backup-snapshots en Gamepad-modi.
  * **Native Renderers:** Schakel flexibel tussen Vulkan (Zink) en OpenGL voor native titels.
  * **Custom Installatiepaden:** Mogelijkheid om per game het bronpad te overschrijven via `installpaths.conf`.
* **Slimme Provisioning & Hooks:** Automatische inrichting van verse prefixen en installatie van afhankelijkheden (zoals VC++ 2019 via runtime-hooks) bij de eerste start.
* **Wayland & AMD RADV Optimalisatie:** Ingebouwde Gamescope-wrapper voorkomt scherm-stalls/focus-problemen bij DXVK exclusive fullscreen op AMD/Wayland.
* **Automatische Desktop Shortcuts:** Genereert bij de eerste start `.desktop`-bestanden op het bureaublad zodat de GUI of terminal niet meer nodig is.

---

## 🕹️ Game Compatibiliteitsoverzicht

| Game | Runner / Renderer | Bijzonderheden & Hooks |
| :--- | :--- | :--- |
| **Angry Birds** | Vanilla Wine / OpenGL | Lichte Wine-modus (geen Proton nodig). Runtimes meegeleverd in gamemap. |
| **Cyberpunk 2077** | GE-Proton / DX12 | `install_vcrun2019` hook vereist. Gebruikt `disable_winebus` (`Enable SDL=0`) voor correcte toetsenbord- en muisinvoer. |
| **Cities: Skylines** | GE-Proton / DX11 | Inclusief `install_gamescope` wrapper tegen Wayland/AMD freezes. Parallelle DXVK shader-compilatie ingeschakeld. |
| **Ori: Blind Forest** | GE-Proton / DX11 | 32-bit Unity Mono build. Automatische resolutie-detectie via Gamescope. |
| **Ori: Will of the Wisps** | GE-Proton / DX11 | Standalone Unity IL2CPP build (`oriandthewillofthewisps-pc.exe`). |

---

## 🛠️ Gebruik

### 1. Grafische Interface (GUI)
Start de GUI vanuit de terminal of dubbelklik op de aangemaakte snelkoppeling:
```bash
python3 /mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/game-gui.py
```
* **Bladeren:** Gebruik de pijltjestoetsen of het muiswiel op de roller.
* **Instellingen:** Vink de gewenste opties aan (zoals Gamescope of Gamepad-modus).
* **Starten:** Klik op een game-card of druk op `Enter`.

### 2. Command Line / Terminal
Je kunt een game-script direct via de bash-terminal aanroepen:
```bash
/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts/game-launchers/cyberpunk2077.sh
```

---

## 📝 Zelf een Game Launcher Toevoegen

Elk launcher-script is een dunne wrapper om `game-common.sh`. Maak een nieuw bestand aan in `template-scripts/game-launchers/<game-naam>.sh`:

```bash
#!/bin/bash
export GAME_NAME="MijnGame"
export GAME_DISPLAY_NAME="Mijn Super Game"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/MijnGame"
export GAME_EXE="$GAME_DIR/MijnGame.exe"
export GAME_ICON="mijngame.png"  # Geplaatst in game-launchers/gameicons/
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Optionele Proton Instellingen
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="123456"

# Optionele Hooks
export PROVISION_HOOKS=("install_vcrun2019")

# Laad de centrale core-logica
source "$(dirname "${BASH_SOURCE[0]}")/../game-core/game-common.sh"
game_main "$@"
```

Maak het script uitvoerbaar:
```bash
chmod +x template-scripts/game-launchers/<game-naam>.sh
```

---

## 📄 Licentie

Dit project is uitgebracht onder de [MIT-licentie](LICENSE).