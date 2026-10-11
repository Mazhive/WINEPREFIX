#!/bin/bash
# hook: install-wine32 — Detecteer of 32-bit Wine beschikbaar is voor win32-prefixes.
#
# Nieuwe WoW64-wine (10.8+/11+) weigert win32-prefixes ("WINEARCH is set to
# 'win32' but this is not supported in wow64 mode"). Die build herkent deze
# hook en adviseert dan een win64-prefix (WoW64 draait 32-bit exe's native,
# zonder lib32-pakketten) — installeren helpt daar niet.
#
# Alleen op legacy-systemen (bv. Debian met echte 32-bit wine) valt de hook
# terug op de OS-specifieke popup (kdialog/zenity, via _gui_confirm in
# game-common.sh) met de installatie-opdracht voor de gedetecteerde distro en
# biedt "Installeer nu" aan (sudo/pkexec, zelfde patroon als
# install_gamescope.sh). Installatie is vrijwillig: "Nee"/annuleren stopt
# provisioning met exit 1 en de gebruiker installeert handmatig.

hook_run() {
  [ "${PREFIX_ARCH:-win64}" = "win32" ] || return 0

  # Test of 32-bit Wine al werkt
  if WINEARCH=win32 wineboot --help >/dev/null 2>&1; then
    _log "hook(install-wine32): 32-bit Wine al beschikbaar."
    return 0
  fi

  # WoW64-build: win32-prefix wordt structureel geweigerd. lib32-pakketten
  # installeren lost dat niet op — de launcher moet een win64-prefix gebruiken.
  if WINEARCH=win32 wineboot --help 2>&1 | grep -qi "wow64"; then
    _log "hook(install-wine32): wine is een WoW64-build; win32-prefix niet ondersteund."
    _gui_message "32-bit prefix niet ondersteund — ${GAME_DISPLAY_NAME:-$GAME_NAME}" \
      "Deze Wine is een WoW64-build en ondersteunt geen win32-prefixes meer.

Zet PREFIX_ARCH=\"win64\" in het launcher-script: een win64-prefix draait
32-bit exe's via WoW64, zonder extra lib32-pakketten."
    return 1
  fi

  local pkgmgr os_name
  pkgmgr="$(_distro_pkg)"
  os_name="$(_os_pretty_name)"

  local cmd="" manual=""
  case "$pkgmgr" in
    apt)
      cmd="dpkg --add-architecture i386 && apt update && apt install -y wine32:i386 libwine:i386 libasound2:i386 libc6:i386 libglib2.0-0:i386 libgphoto2-6:i386 libgstreamer-plugins-base1.0-0:i386 libldap-2.4-2:i386 libopenal1:i386 libpcap0.8:i386 libpulse0:i386 libsane1:i386 libudev1:i386 libvkd3d1:i386 libx11-6:i386 libxext6:i386 libxml2:i386 libxslt1.1:i386 zlib1g:i386"
      ;;
    pacman)
      manual="Zet eerst [multilib] aan in /etc/pacman.conf (Include = /etc/pacman.d/mirrorlist) en draai 'pacman -Sy'."
      cmd="pacman -S --needed --noconfirm wine lib32-gnutls lib32-libldap lib32-libgpg-error lib32-sqlite lib32-libpulse lib32-alsa-lib lib32-libx11 lib32-libxext lib32-libxml2 lib32-zlib lib32-vkd3d"
      ;;
    dnf)
      cmd="dnf install -y wine.i686 wine-common.i686 alsa-lib.i686 glibc.i686 libgcc.i686 libstdc++.i686 libX11.i686 libXext.i686 libxml2.i686 libxslt.i686 zlib.i686 vkd3d.i686 gstreamer1-plugins-base.i686"
      ;;
    zypper)
      cmd="zypper install -y wine-32bit"
      ;;
    *)
      _log "hook(install-wine32): pakketbeheerder '$pkgmgr' niet herkend; installeer 32-bit Wine handmatig."
      _gui_message "32-bit Wine ontbreekt — ${GAME_DISPLAY_NAME:-$GAME_NAME}" \
        "Gedetecteerd OS: ${os_name}

Deze game vereist 32-bit Wine, maar die is niet beschikbaar.
Installeer 32-bit Wine handmatig voor jouw distributie (wine32, wine.i686, wine-32bit of wine[abi_x86_32]) en herstart daarna de launcher."
      return 1
      ;;
  esac

  local body="Gedetecteerd OS: ${os_name}

Deze game vereist 32-bit Wine, maar die is niet beschikbaar.
${manual:+$manual
}Installeer het nu?

  $cmd

(Herstart daarna de launcher.)"

  _log "hook(install-wine32): 32-bit Wine NIET beschikbaar."
  _log "Installatie-opdracht: $cmd"

  if ! _gui_confirm "32-bit Wine ontbreekt — ${GAME_DISPLAY_NAME:-$GAME_NAME}" "$body"; then
    _log "hook(install-wine32): installatie geweigerd/geannuleerd. Installeer 32-bit Wine handmatig en herstart de launcher."
    return 1
  fi

  _log "hook(install-wine32): installatie gestart via sudo/pkexec..."
  if [ "$(id -u)" -eq 0 ]; then
    bash -c "$cmd"
  elif command -v sudo >/dev/null 2>&1; then
    sudo bash -c "$cmd"
  elif command -v pkexec >/dev/null 2>&1; then
    pkexec bash -c "$cmd"
  else
    _log "hook(install-wine32): geen root en geen sudo/pkexec — installeer 32-bit Wine handmatig."
    return 1
  fi

  if WINEARCH=win32 wineboot --help >/dev/null 2>&1; then
    _log "hook(install-wine32): 32-bit Wine nu beschikbaar."
    return 0
  fi
  _log "hook(install-wine32): installatie leek te lukken maar 32-bit Wine is nog niet vindbaar."
  return 1
}