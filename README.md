# Wineprefix Templates for Shared Games

A modular, lightweight script and GUI system for Linux environments, designed to play shared Windows games from a central Network File System (NFS) share with isolated, local Wine prefixes per user.

---

## 🚀 Overview

Running Windows games directly from an NFS share by multiple users often causes file locking conflicts and permission issues within the Wine prefix.

This project solves this through a **hybrid architecture**:
* **Game files** reside centrally on the NFS share (read-only for players).
* **Wine prefixes** are created fresh and locally for each user in `~/GAMEPREFIXES/<Game>/`.
* **Modular Launchers:** Scripts on the share contain the startup logic. They work completely independently via the terminal or through the included PySide6 GUI (`game-gui.py`).

---

## 🏗️ Architecture & Directory Structure

```
NFS Share (Shared, Read-Only/Read-Mostly)
└─ PRE-INSTALLED-GAMES/
   ├─ WINDOWSGAMES/<Game>/        # Original game files (exes, assets)
   └─ WINEPREFIX/
      ├─ game-gui.py              # PySide6 Graphical Interface
      └─ template-scripts/
         ├─ game-core/
         │  ├─ game-common.sh     # Reusable core (provisioning, launching, desktop icon)
         │  └─ hooks/             # Modular hooks (VC++ redists, winebus tweaks, gamescope)
         ├─ game-launchers/
         │  ├─ LINUXLAUNCHERS/    # Shortcuts to active launcher scripts (*.sh)
         │  │  └─ gameicons/      # Images and icons for the GUI
         │  ├─ angry-birds.sh     # Thin launcher script (vanilla Wine)
         │  ├─ cyberpunk2077.sh   # Launcher with GE-Proton + VC++ Hooks
         │  └─ citiesskylines.sh  # Launcher with Proton + Gamescope wrap
         └─ tools/
            ├─ install-proton.sh  # Automatic GE-Proton installer
            ├─ ask-yesno.sh       # Reusable TTY/GUI prompt helper
            └─ gamepad-status.sh  # Helper for gamepad diagnostics

Local (Per User on their own PC)
└─ ~/GAMEPREFIXES/
   └─ <Game>/
      ├─ pfx/                    # Local Wine prefix (player-owned)
      ├─ compatdata/<appid>/     # Proton compatibility folder (symlink)
      └─ .provisioned            # Version marker for automatic updates
```

---

## 🔑 Key Features

* **Isolated Execution:** No network lock conflicts. Every player has their own local prefix and settings.
* **PySide6 Graphical Interface (`game-gui.py`):**
  * **Interactive Cover Roller:** Visually browse available games with custom icons and automatic fallback placeholders.
  * **Live Terminal Log Streaming:** View the `stdout`/`stderr` of the game and launchers instantly via `QProcess`.
  * **Startup Parameter Toggles:** Easily check boxes for Desktop shortcuts, Gamescope wrapping, SDL3 fallbacks, backup snapshots, and gamepad modes.
  * **Native Renderers:** Flexibly switch between Vulkan (Zink) and OpenGL for native titles.
  * **Custom Installation Paths:** Ability to override the source path per game via `installpaths.conf`.
* **Smart Provisioning & Hooks:** Automatic setup of fresh prefixes and installation of dependencies (such as VC++ 2019 via runtime hooks) on first launch.
* **Wayland & AMD RADV Optimization:** Built-in Gamescope wrapper prevents screen stalls/focus issues during DXVK exclusive fullscreen on AMD/Wayland.
* **Automatic Desktop Shortcuts:** Generates `.desktop` files on the desktop on first launch so the GUI or terminal is no longer needed.

---

## 🕹️ Game Compatibility Overview

| Game | Runner / Renderer | Specifics & Hooks |
| :--- | :--- | :--- |
| **Angry Birds** | Vanilla Wine / OpenGL | Light Wine mode (Proton not required). Runtimes included in game folder. |
| **Cyberpunk 2077** | GE-Proton / DX12 | Requires `install_vcrun2019` hook. Uses `disable_winebus` (`Enable SDL=0`) for correct keyboard and mouse input. |
| **Cities: Skylines** | GE-Proton / DX11 | Includes `install_gamescope` wrapper against Wayland/AMD freezes. Parallel DXVK shader compilation enabled. |
| **Ori: Blind Forest** | GE-Proton / DX11 | 32-bit Unity Mono build. Automatic resolution detection via Gamescope. |
| **Ori: Will of the Wisps** | GE-Proton / DX11 | Standalone Unity IL2CPP build (`oriandthewillofthewisps-pc.exe`). |

---

## 🛠️ Usage

### 1. Graphical Interface (GUI)
Launch the GUI from the terminal or double-click the generated shortcut:
```bash
python3 /mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/game-gui.py
```
* **Browse:** Use the arrow keys or mouse wheel on the roller.
* **Settings:** Check the desired options (such as Gamescope or Gamepad mode).
* **Launch:** Click a game card or press `Enter`.

### 2. Command Line / Terminal
You can call a game script directly via the bash terminal:
```bash
/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts/game-launchers/cyberpunk2077.sh
```

---

## 📝 Adding a Custom Game Launcher

Each launcher script is a thin wrapper around `game-common.sh`. Create a new file in `template-scripts/game-launchers/<game-name>.sh`:

```bash
#!/bin/bash
export GAME_NAME="MyGame"
export GAME_DISPLAY_NAME="My Super Game"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINDOWSGAMES/MyGame"
export GAME_EXE="$GAME_DIR/MyGame.exe"
export GAME_ICON="mygame.png"  # Placed in game-launchers/gameicons/
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Optional Proton Settings
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="123456"

# Optional Hooks
export PROVISION_HOOKS=("install_vcrun2019")

# Load central core logic
source "$(dirname "${BASH_SOURCE[0]}")/../game-core/game-common.sh"
game_main "$@"
```

Make the script executable:
```bash
chmod +x template-scripts/game-launchers/<game-name>.sh
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).