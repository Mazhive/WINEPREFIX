#!/bin/bash
# hook: install-wine32 — Detecteer of 32-bit Wine beschikbaar is voor win32-prefixes.
# Alleen INFORMATIEF: toont benodigde pakketten per distro, installeert NIET.

hook_run() {
  [ "${PREFIX_ARCH:-win64}" = "win32" ] || return 0

  # Test of 32-bit Wine al werkt
  if WINEARCH=win32 wineboot --help >/dev/null 2>&1; then
    _log "hook(install-wine32): 32-bit Wine al beschikbaar."
    return 0
  fi

  local pkgmgr
  pkgmgr="$(_distro_pkg)"

  _log "================================================================"
  _log "hook(install-wine32): 32-bit Wine NIET beschikbaar."
  _log "Deze game vereist een 32-bit Wine-prefix (PREFIX_ARCH=win32)."
  _log "Installeer de benodigde 32-bit Wine pakketten voor jouw distro:"
  _log "================================================================"

  case "$pkgmgr" in
    apt)
      _log ""
      _log "=== Debian / Ubuntu / Mint / Pop / Elementary / Zorin ==="
      _log "Voer uit als root (of met sudo):"
      _log "  dpkg --add-architecture i386"
      _log "  apt update"
      _log "  apt install wine32:i386 libwine:i386 libasound2:i386 libc6:i386 \\"
      _log "       libglib2.0-0:i386 libgphoto2-6:i386 \\"
      _log "       libgstreamer-plugins-base1.0-0:i386 libldap-2.4-2:i386 \\"
      _log "       libopenal1:i386 libpcap0.8:i386 libpulse0:i386 \\"
      _log "       libsane1:i386 libudev1:i386 libvkd3d1:i386 \\"
      _log "       libx11-6:i386 libxext6:i386 libxml2:i386 libxslt1.1:i386 zlib1g:i386"
      ;;
    pacman)
      _log ""
      _log "=== Arch / Manjaro / EndeavourOS / CachyOS ==="
      _log "Vereist: [multilib] repository ingeschakeld in /etc/pacman.conf"
      _log "  # Voeg toe aan /etc/pacman.conf:"
      _log "  [multilib]"
      _log "  Include = /etc/pacman.d/mirrorlist"
      _log ""
      _log "Dan als root:"
      _log "  pacman -Sy"
      _log "  pacman -S wine lib32-gnutls lib32-libldap lib32-libgpg-error \\"
      _log "       lib32-sqlite lib32-libpulse lib32-alsa-lib lib32-libx11 \\"
      _log "       lib32-libxext lib32-libxml2 lib32-libxslt lib32-zlib \\"
      _log "       lib32-vkd3d lib32-gst-plugins-base-libs"
      ;;
    dnf)
      _log ""
      _log "=== Fedora / RHEL / CentOS / Rocky / AlmaLinux ==="
      _log "Als root:"
      _log "  dnf install wine.i686 wine-common.i686 alsa-lib.i686 glibc.i686 \\"
      _log "       libgcc.i686 libstdc++.i686 libX11.i686 libXext.i686 \\"
      _log "       libxml2.i686 libxslt.i686 zlib.i686 vkd3d.i686 \\"
      _log "       gstreamer1-plugins-base.i686"
      ;;
    zypper)
      _log ""
      _log "=== openSUSE Leap / Tumbleweed ==="
      _log "Als root:"
      _log "  zypper install wine-32bit"
      ;;
    *)
      _log ""
      _log "=== Onbekende distro ($pkgmgr) ==="
      _log "Installeer 32-bit Wine handmatig voor jouw distributie."
      _log "Zoek naar pakketten als: wine32, wine.i686, wine-32bit, of wine[abi_x86_32]"
      ;;
  esac

  _log ""
  _log "================================================================"
  _log "Na installatie: herstart deze launcher."
  _log "================================================================"

  return 1
}