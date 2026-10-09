# Wineprefix Templates for Shared Games

A modular, lightweight script system for Linux environments designed to launch shared Windows games from a Central Network File System (NFS) share, running on isolated, per-user local Wine prefixes.

---

## 🚀 Overview

Running shared Windows games on a multi-user Linux setup often leads to Wine lock conflicts and permission issues when prefixes are hosted directly on network shares. 

This repository provides a modular, GUI-agnostic bash framework that solves this problem:
* **Centralized Game Files:** All game installations reside on a shared NFS mount (read-mostly).
* **Local Fresh Prefixes:** Clean Wine prefixes are dynamically created per user in their local home directory (`~/GAMEPREFIXES/<Game>/`).
* **Modular Scripts:** Core logic (provisioning, environment detection, runners, shortcuts) is decoupled from individual game definitions, making adding new games trivial.

---

## 🏗️ Architecture & Directory Structure

```text
NFS Share (Read-Only/Shared)
└─ PRE-INSTALLED-GAMES/
   ├─ WINDOWSGAMES/<Game>/        # Clean Windows game files
   └─ WINEPREFIX/
      └─ template-scripts/
         ├─ game-core/
         │  ├─ game-common.sh     # Modular core (provisioning, launching, desktop entries)
         │  └─ hooks/            # Modular hooks (VC++ Redists, Winebus tweaks, Gamescope)
         ├─ game-launchers/
         │  ├─ angry-birds.sh     # Minimal launcher (vanilla Wine)
         │  ├─ cyberpunk2077.sh   # Advanced launcher (GE-Proton + VC++ Hooks + Winebus)
         │  └─ citiesskylines.sh  # Advanced launcher (Proton + Gamescope wrap)
         └─ tools/
            ├─ install-proton.sh  # Automatic GE-Proton installer
            └─ ask-yesno.sh       # Native UI/TTY confirmation helper

Local Machine (Per User)
└─ ~/GAMEPREFIXES/
   └─ <Game>/
      ├─ pfx/                    # Isolated local Wine prefix (User-owned)
      ├─ compatdata/<appid>/     # Proton compatibility layer structure
      └─ .provisioned            # Marker tracking script/provision version
```

---

## 🔑 Key Features

- **Isolated Execution:** Ensures Wine lock files and registry modifications remain local to the executing user account.
- **Proton & Wine Support:** Native compatibility with generic Wine as well as GE-Proton releases with ProtonFixes support.
- **Smart Provisioning:** Automatically initializes missing local prefixes, registers DXVK/VKD3D environments, and runs game-specific dependencies (e.g., `vcrun2019`) only on initial boot or script updates.
- **Wayland / AMD Compatibility:** Includes built-in support for auto-resolving Gamescope wrappers to fix exclusive fullscreen display stalls under AMD RADV/Wayland.
- **Automatic Desktop Shortcuts:** Auto-generates standard `.desktop` entries on initial launch, enabling users to launch games from their system application menu without touching the terminal again.

---

## 🛠️ Usage

### Running a Game Launcher

To launch a game, run its specific script from the share:

```bash
/path/to/share/WINEPREFIX/template-scripts/game-launchers/cyberpunk2077.sh
```

1. **First Run:** The core script automatically provisions `~/GAMEPREFIXES/Cyberpunk2077/`, executes required setup hooks, creates a `.desktop` application menu entry, and launches the game.
2. **Subsequent Runs:** Bypasses provisioning and directly launches the game using the existing local prefix or desktop entry.

---

## 📝 Creating a New Game Launcher

Game launchers are lightweight wrappers around `game-common.sh`. To add a new game, create a script inside `template-scripts/game-launchers/`:

```bash
#!/bin/bash
export GAME_NAME="ExampleGame"
export GAME_DIR="/path/to/share/WINDOWSGAMES/ExampleGame"
export GAME_EXE="$GAME_DIR/ExampleGame.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_LAUNCHER="$(readlink -f "$0")"

# Optional Proton Settings
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="123456"

# Optional Provisioning & Pre-launch Hooks
export PROVISION_HOOKS=("install_vcrun2019")

# Load core runner
source "$(dirname "${BASH_SOURCE[0]}")/../game-core/game-common.sh"
game_main "$@"
```

---

## 🕹️ Supported Game Compatibility Notes

| Game | Renderer / Runner | Configuration Notes |
| :--- | :--- | :--- |
| **Angry Birds** | OpenGL 2 / Vanilla Wine | Native Wine runner. Dependencies bundled within game directory. |
| **Cyberpunk 2077** | DX12 / GE-Proton | Requires `install_vcrun2019` hook. Employs `disable_winebus` hook (`Enable SDL=0`) to ensure proper keyboard/mouse handling. |
| **Cities: Skylines** | DX11 / GE-Proton | Utilizes `install_gamescope` wrapper for Wayland/AMD RADV environments to prevent swapchain stalls. Auto-detects desktop resolution. |
| **Ori: Blind Forest** | DX11 / GE-Proton | 32-bit executable using CODEX configuration. Runs under isolated desktop wrapper. |
| **Ori: Will of the Wisps** | DX11 / GE-Proton | Unity IL2CPP standalone PC build. |

---

## 📄 License

This repository is distributed under the MIT License. See `LICENSE` for details.