# Game Launcher Dependencies (dep.md)
# Generated from analysis of game-gui.py
# Supports: Windows, Debian, Ubuntu, Arch, CachyOS, Fedora, openSUSE, Alpine, NixOS

## Python Dependencies (Required on ALL platforms)

- **Python**: >= 3.8 (3.10+ recommended)
- **PySide6**: >= 6.4 (Qt6 bindings) - CORE GUI FRAMEWORK

Python stdlib modules used (no extra install needed):
- `os`, `re`, `signal`, `pathlib`

## Linux Distribution Packages

### Debian / Ubuntu / Linux Mint / Pop!_OS / Kali / Parrot

```bash
# Core GUI
sudo apt update && sudo apt install -y python3 python3-pip python3-venv
sudo apt install -y python3-pyside6

# System tools used by launcher scripts
sudo apt install -y bash coreutils findutils grep sed gawk

# Gamepad / SDL / Gamescope support
sudo apt install -y libsdl2-2.0-0 libsdl3-0 libvulkan1 mesa-vulkan-drivers
sudo apt install -y gamescope                    # Gamescope compositor
sudo apt install -y libinput-tools udev          # Gamepad udev rules
sudo apt install -y vulkan-tools                 # vulkaninfo, vkcube

# Wine / Proton (for Windows games in WINEPREFIX)
sudo apt install -y wine wine64 winetricks
sudo apt install -y gamemode libgamemode0        # Feral GameMode

# Desktop integration
sudo apt install -y xdg-utils desktop-file-utils

# Optional: Steam runtime libraries (for Proton)
sudo apt install -y lib32gcc-s1 lib32stdc++6 lib32z1
```

### Arch Linux / CachyOS / EndeavourOS / Manjaro / Garuda

```bash
# Core GUI
sudo pacman -S python python-pip
sudo pacman -S python-pyside6                    # or: pyside6 (meta-package)

# System tools
sudo pacman -S bash coreutils findutils grep sed gawk

# Gamepad / SDL / Gamescope
sudo pacman -S sdl2 sdl3 vulkan-icd-loader mesa
sudo pacman -S gamescope                         # Gamescope (AUR: gamescope-git for latest)
sudo pacman -S libinput udev
sudo pacman -S vulkan-tools

# Wine / Proton
sudo pacman -S wine winetricks
sudo pacman -S gamemode lib32-gamemode

# Desktop integration
sudo pacman -S xdg-utils desktop-file-utils

# Multilib (required for 32-bit Wine)
# Enable [multilib] in /etc/pacman.conf first
sudo pacman -S lib32-mesa lib32-vulkan-icd-loader lib32-sdl2 lib32-sdl3

# AUR helpers (optional, for gamescope-git, proton-ge-custom, etc.)
# yay -S gamescope-git proton-ge-custom
```

### Fedora / RHEL / CentOS Stream / AlmaLinux / Rocky / Nobara

```bash
# Core GUI
sudo dnf install python3 python3-pip python3-virtualenv
sudo dnf install python3-pyside6

# System tools
sudo dnf install bash coreutils findutils grep sed gawk

# Gamepad / SDL / Gamescope
sudo dnf install SDL2 SDL3 vulkan-loader mesa-vulkan-drivers
sudo dnf install gamescope                       # Fedora 38+
sudo dnf install libinput udev
sudo dnf install vulkan-tools

# Wine / Proton
sudo dnf install wine wine-core winetricks
sudo dnf install gamemode

# Desktop integration
sudo dnf install xdg-utils desktop-file-utils

# 32-bit libraries for Wine
sudo dnf install mesa-vulkan-drivers.i686 vulkan-loader.i686 SDL2.i686 SDL3.i686

# RPM Fusion (recommended for codecs, drivers)
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

### openSUSE Leap / Tumbleweed / Slowroll

```bash
# Core GUI
sudo zypper install python3 python3-pip python3-virtualenv
sudo zypper install python3-pyside6

# System tools
sudo zypper install bash coreutils findutils grep sed gawk

# Gamepad / SDL / Gamescope
sudo zypper install libSDL2-2_0-0 libSDL3-0 vulkan-loader Mesa-libvulkan
sudo zypper install gamescope
sudo zypper install libinput-tools udev
sudo zypper install vulkan-tools

# Wine / Proton
sudo zypper install wine winetricks
sudo zypper install gamemode

# Desktop integration
sudo zypper install xdg-utils desktop-file-utils

# 32-bit libraries
sudo zypper install Mesa-libvulkan-32bit vulkan-loader-32bit libSDL2-2_0-0-32bit libSDL3-0-32bit
```

### Alpine Linux

```bash
# Core GUI
sudo apk add python3 py3-pip py3-virtualenv
sudo apk add py3-pyside6

# System tools
sudo apk add bash coreutils findutils grep sed gawk

# Gamepad / SDL / Gamescope
sudo apk add sdl2 sdl3 vulkan-loader mesa-vulkan
sudo apk add gamescope                           # edge/testing repository
sudo apk add libinput udev
sudo apk add vulkan-tools

# Wine (limited on musl - consider flatpak/steam)
sudo apk add wine                                # may need x86_64 glibc chroot

# Desktop integration
sudo apk add xdg-utils desktop-file-utils
```

### NixOS

Add to `configuration.nix`:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python3
    python3Packages.pyside6
    bash coreutils findutils gnugrep gnused gawk
    sdl2 sdl3 vulkan-loader mesa
    gamescope
    libinput udev
    vulkan-tools
    wine winetricks
    gamemode
    xdg-utils desktop-file-utils
  ];
}
```

Or ad-hoc shell:

```bash
nix-shell -p python3 python3Packages.pyside6 bash coreutils findutils gnugrep gnused gawk sdl2 sdl3 vulkan-loader mesa gamescope libinput udev vulkan-tools wine winetricks gamemode xdg-utils desktop-file-utils
```

### Gentoo

```bash
# Core GUI
emerge -av dev-lang/python:3.11 dev-python/pip
emerge -av dev-python/PySide6

# System tools (already present)
# sys-apps/bash sys-apps/coreutils sys-apps/findutils sys-apps/grep sys-apps/sed sys-apps/gawk

# Gamepad / SDL / Gamescope
emerge -av media-libs/libsdl2 media-libs/libsdl3 dev-util/vulkan-tools
emerge -av media-libs/mesa[ vulkan ]
emerge -av games-util/gamescope
emerge -av sys-libs/libinput sys-fs/udev

# Wine / Proton
emerge -av app-emulation/wine app-emulation/winetricks
emerge -av sys-apps/gamemode

# Desktop integration
emerge -av x11-misc/xdg-utils x11-misc/desktop-file-utils

# 32-bit (enable abi_x86_32 in make.conf)
# emerge -av media-libs/mesa[abi_x86_32] dev-util/vulkan-loader[abi_x86_32] media-libs/libsdl2[abi_x86_32]
```

### Void Linux

```bash
# Core GUI
xbps-install -S python3 python3-pip
xbps-install -S python3-pyside6

# System tools
xbps-install -S bash coreutils findutils grep sed gawk

# Gamepad / SDL / Gamescope
xbps-install -S SDL2 SDL3 vulkan-loader mesa-vulkan
xbps-install -S gamescope
xbps-install -S libinput udev
xbps-install -S vulkan-tools

# Wine / Proton
xbps-install -S wine winetricks
xbps-install -S gamemode

# Desktop integration
xbps-install -S xdg-utils desktop-file-utils
```

### Solus

```bash
# Core GUI
eopkg install python3 pip
eopkg install pyside6

# System tools (base)
# Gamepad / SDL / Gamescope
eopkg install sdl2 sdl3 vulkan-loader mesa
eopkg install gamescope
eopkg install libinput udev
eopkg install vulkan-tools

# Wine / Proton
eopkg install wine winetricks
eopkg install gamemode

# Desktop integration
eopkg install xdg-utils desktop-file-utils
```

## Windows Dependencies

### Native Windows (No Wine needed - runs Windows games directly)

1. **Python**: Download from [python.org/downloads/windows](https://python.org/downloads/windows/) - Install Python 3.10+ (check "Add to PATH")
2. **PySide6**: `pip install pyside6`
3. **Git for Windows** (provides bash, coreutils, etc.): Download from [git-scm.com/download/win](https://git-scm.com/download/win) - During install: select "Use Git and optional Unix tools from Command Prompt"
4. **Visual C++ Redistributable** (required for some Python packages): [aka.ms/vs/17/release/vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe)

**Alternative: WSL2** (recommended for launcher scripts compatibility)
```powershell
wsl --install -d Ubuntu
# Then follow Ubuntu/Debian instructions inside WSL
```

**Optional package managers:**
```powershell
# Scoop
scoop install python git
pip install pyside6

# Chocolatey
choco install python git
pip install pyside6

# Winget
winget install Python.Python.3.11 Git.Git
pip install pyside6
```

**Optional:** Windows Terminal - `winget install Microsoft.WindowsTerminal`

### Windows with Wine (Cross-compiling / testing Linux games)

Not typical - use WSL2 or VM instead.

## Flatpak / Snap / AppImage Alternatives (Distro-agnostic)

```bash
# PySide6 via Flatpak (for development)
flatpak install flathub org.kde.Platform//6.6
flatpak install flathub org.kde.Sdk//6.6
# Then use flatpak run --command=python3 org.kde.Sdk//6.6

# PySide6 via pipx (isolated)
pipx install pyside6

# Gamescope via Flatpak
flatpak install flathub org.freedesktop.Platform.VulkanLayer.gamescope

# Wine via Flatpak (bottles)
flatpak install flathub com.usebottles.bottles

# Steam (includes Proton, gamescope, SDL, Vulkan)
flatpak install flathub com.valvesoftware.Steam
```

## Game-Specific Runtime Dependencies (Referenced in launcher scripts)

These are typically handled by the individual game launcher scripts but may be needed system-wide:

### Vulkan ICD Loaders (per GPU vendor)
- **NVIDIA**: `nvidia-vulkan-icd` / `nvidia-driver` (proprietary)
- **AMD**: `mesa-vulkan-drivers` (radv) / `amdvlk` (proprietary)
- **Intel**: `mesa-vulkan-drivers` (anv)

### DXVK / VKD3D-Proton (for Wine/D3D games)
Usually provided by Proton/Steam, or install system-wide:
- **Debian/Ubuntu**: `apt install dxvk vkd3d`
- **Arch**: `pacman -S dxvk vkd3d`
- **Fedora**: `dnf install dxvk vkd3d`
- **openSUSE**: `zypper install dxvk vkd3d`

### GameMode (Feral Interactive)
- **Debian/Ubuntu**: `apt install gamemode libgamemode0`
- **Arch**: `pacman -S gamemode lib32-gamemode`
- **Fedora**: `dnf install gamemode`
- **openSUSE**: `zypper install gamemode`

### MangoHud (overlay)
- **Debian/Ubuntu**: `apt install mangohud`
- **Arch**: `pacman -S mangohud`
- **Fedora**: `dnf install mangohud`

### Proton-GE (custom Proton builds)
Use `protonup-qt` or `protonup`:
```bash
pipx install protonup-qt
```
Or download from: [github.com/GloriousEggroll/proton-ge-custom](https://github.com/GloriousEggroll/proton-ge-custom)

## Filesystem / Configuration Requirements

### Directory structure expected by game-gui.py
```
/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/
├── game-gui.py                    # Main launcher (this file)
├── gamelauncherv1.png             # Application icon
├── template-scripts/
│   ├── game-launchers/
│   │   ├── LINUXLAUNCHERS/        # *.sh launcher scripts
│   │   └── gameicons/             # PNG/JPG/WebP icons
│   └── tools/
│       └── gamepad-status.sh      # Gamepad detection script
```

### User config directories (auto-created)
```
~/.config/gamelauncher/
├── installpaths.conf              # GAME_DIR_<GAME>="path"
└── settings.conf                  # GPAD=1, etc.
```

### Desktop entry (auto-created on first run)
```
~/Desktop/GameLauncher.desktop
```

## Hardware / Kernel Requirements

- **Kernel**: Linux 5.10+ (6.1+ recommended for better gamepad/hardware support)
- **GPU Drivers**:
  - **NVIDIA**: 535+ (proprietary) or Nouveau (limited Vulkan)
  - **AMD**: Mesa 23.1+ (radv/anv) - included in distro packages
  - **Intel**: Mesa 23.1+ (anv) - included in distro packages
- **Vulkan**: 1.3+ support required for modern games
- **Gamescope**: Requires Wayland compositor (KWin, Hyprland, Sway, etc.) - X11 fallback works but with limitations
- **Gamepad**: udev rules for non-XInput controllers (DualSense, Switch Pro, 8BitDo, etc.) - See `/usr/lib/udev/rules.d/99-gamepad.rules` (or similar)

## Quick Install Commands Summary

| Distro | Command |
|---|---|
| **Debian/Ubuntu/Mint/Pop/Kali** | `sudo apt update && sudo apt install -y python3 python3-pyside6 bash coreutils findutils grep sed gawk libsdl2-2.0-0 libsdl3-0 vulkan-tools mesa-vulkan-drivers gamescope libinput-tools udev wine winetricks gamemode xdg-utils desktop-file-utils` |
| **Arch/CachyOS/Endeavour/Manjaro/Garuda** | `sudo pacman -S python python-pyside6 bash coreutils findutils grep sed gawk sdl2 sdl3 vulkan-icd-loader mesa gamescope libinput udev vulkan-tools wine winetricks gamemode xdg-utils desktop-file-utils lib32-mesa lib32-vulkan-icd-loader lib32-sdl2 lib32-sdl3` |
| **Fedora/Nobara/RHEL/CentOS/Alma/Rocky** | `sudo dnf install python3 python3-pyside6 bash coreutils findutils grep sed gawk SDL2 SDL3 vulkan-loader mesa-vulkan-drivers gamescope libinput udev vulkan-tools wine winetricks gamemode xdg-utils desktop-file-utils mesa-vulkan-drivers.i686 vulkan-loader.i686 SDL2.i686 SDL3.i686` |
| **openSUSE** | `sudo zypper install python3 python3-pyside6 bash coreutils findutils grep sed gawk libSDL2-2_0-0 libSDL3-0 vulkan-loader Mesa-libvulkan gamescope libinput-tools udev vulkan-tools wine winetricks gamemode xdg-utils desktop-file-utils Mesa-libvulkan-32bit vulkan-loader-32bit libSDL2-2_0-0-32bit libSDL3-0-32bit` |
| **Alpine** | `sudo apk add python3 py3-pyside6 bash coreutils findutils grep sed gawk sdl2 sdl3 vulkan-loader mesa-vulkan gamescope libinput udev vulkan-tools wine xdg-utils desktop-file-utils` |
| **NixOS (configuration.nix)** | `environment.systemPackages = with pkgs; [ python3 python3Packages.pyside6 bash coreutils findutils gnugrep gnused gawk sdl2 sdl3 vulkan-loader mesa gamescope libinput udev vulkan-tools wine winetricks gamemode xdg-utils desktop-file-utils ];` |
| **Windows (PowerShell as Admin)** | `winget install Python.Python.3.11 Git.Git; pip install pyside6` |

## Verification Commands

```bash
# Verify Python + PySide6
python3 -c "import sys; print(sys.version)"
python3 -c "from PySide6.QtCore import qVersion; from PySide6.QtWidgets import QApplication; print('PySide6:', qVersion())"

# Verify system tools
bash --version
which gamescope vulkaninfo wine winetricks

# Verify Vulkan
vulkaninfo --summary

# Verify gamepad
udevadm info /dev/input/js0 2>/dev/null || echo "No joystick detected"
```

## Notes

1. **PySide6 is the ONLY mandatory Python package** - everything else is stdlib.
2. The launcher scripts (`*.sh` in `LINUXLAUNCHERS/`) may have their own dependencies (specific Wine versions, Proton, DXVK, etc.) - check individual scripts.
3. **Gamescope** requires a Wayland session for full functionality. On X11 it works but without HDR/VRR/nested compositing benefits.
4. **For NVIDIA GPUs**: ensure `nvidia-driver` + `nvidia-vulkan-icd` are installed. Add `nvidia-drm.modeset=1` to kernel cmdline for Wayland/Gamescope.
5. **Gamepad support** for non-XInput controllers (DualSense, Switch Pro, 8BitDo, etc.) requires udev rules. Most distros include these in `libinput` or `udev` packages.
6. The `gamepad-status.sh` tool checks for SDL_GameControllerDB and udev rules.
7. **WINEPREFIX path is hardcoded** in `game-gui.py` (line 30): `TEMPLATE_ROOT = Path("/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts")` - Adjust if your path differs.
8. Application icon `gamelauncherv1.png` must exist in the same directory as `game-gui.py` or the desktop entry will use a fallback generic icon.
9. **For Windows**: The `.sh` launcher scripts require bash. Git for Windows provides this. Native Windows games don't need Wine - the launcher passes env vars to the game directly.
10. **CachyOS users**: Use the Arch commands. CachyOS kernels (cachy, bo-re) have gaming optimizations (sched-ext, BORE) that benefit game performance.