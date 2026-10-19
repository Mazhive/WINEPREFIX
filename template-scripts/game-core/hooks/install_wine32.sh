#!/bin/bash
# hook: install-wine32 — Detecteer of 32-bit Wine beschikbaar is voor win32-prefixes.
#
# Nieuwe WoW64-wine (10.8+/11+) weigert win32-prefixes ("WINEARCH is set to
# 'win32' but this is not supported in wow64 mode"). Die build herkent deze
# hook en adviseert dan een win64-prefix (WoW64 draait 32-bit exe's native,
# zonder lib32-pakketten).
#
# Op legacy-systemen (bv. Debian met echte 32-bit wine) vraagt de hook via
# ask-yesno.sh om bevestiging aan de gebruiker en installeert 32-bit Wine
# via de distro-pakketbeheerder (sudo/pkexec).

_wine32_probe() {
  local probe rc
  probe="$(mktemp -d)"
  _WINE32_PROBE_OUT="$(WINEPREFIX="$probe" WINEARCH=win32 wineboot --help 2>&1)"
  rc=$?
  WINEPREFIX="$probe" wineserver -k 2>/dev/null || true
  rm -rf "$probe"
  return "$rc"
}

hook_run() {
  [ "${PREFIX_ARCH:-win64}" = "win32" ] || return 0

  # Test of 32-bit Wine al werkt
  if _wine32_probe; then
    _log "hook(install-wine32): 32-bit Wine al beschikbaar."
    return 0
  fi

  # WoW64-build: win32-prefix wordt structureel geweigerd.
  if printf '%s' "$_WINE32_PROBE_OUT" | grep -qi "wow64"; then
    _log "hook(install-wine32): wine is een WoW64-build; win32-prefix niet ondersteund."
    _log "hook(install-wine32): zet PREFIX_ARCH=\"win64\" in het launcher-script (win64 draait 32-bit exe's via WoW64, zonder lib32-pakketten)."
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
      _log "hook(install-wine32): OS: ${os_name}. Installeer wine32 / wine.i686 / wine-32bit / wine[abi_x86_32] en herstart de launcher."
      return 1
      ;;
  esac

  _log "hook(install-wine32): 32-bit Wine is nodig voor deze game, maar ontbreekt (OS: ${os_name})."

  # Vraag interactief om toestemming via ask-yesno.sh (GUI / CLI)
  local base_dir
  base_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"
  if [ -x "$base_dir/tools/ask-yesno.sh" ]; then
    if ! "$base_dir/tools/ask-yesno.sh" --title "32-bit Wine vereist" \
         --message "32-bit Wine ontbreekt op ${os_name}.\n\nMogen de vereiste 32-bit pakketten nu geïnstalleerd worden? (Hierbij wordt om je wachtwoord gevraagd)"; then
      _log "hook(install-wine32): Installatie van 32-bit Wine geannuleerd door gebruiker."
      return 1
    fi
  fi

  _log "hook(install-wine32): Het wordt nu geïnstalleerd; er wordt zo om je wachtwoord gevraagd."
  _log "hook(install-wine32): Opdracht: $cmd"
  if [ -n "$manual" ]; then
    _log "hook(install-wine32): $manual"
  fi

  local rc=0
  if [ "$(id -u)" -eq 0 ]; then
    bash -c "$cmd" || rc=$?
  elif command -v sudo >/dev/null 2>&1; then
    sudo bash -c "$cmd" || rc=$?
  elif command -v pkexec >/dev/null 2>&1; then
    pkexec bash -c "$cmd" || rc=$?
  else
    _log "hook(install-wine32): geen root en geen sudo/pkexec — installeer 32-bit Wine handmatig."
    return 1
  fi

  if [ "$rc" -ne 0 ]; then
    _log "hook(install-wine32): installatie-opdracht faalde (rc=$rc)."
    return 1
  fi

  if _wine32_probe; then
    _log "hook(install-wine32): 32-bit Wine nu beschikbaar."
    return 0
  fi
  _log "hook(install-wine32): installatie leek te lukken maar 32-bit Wine is nog niet vindbaar."
  return 1
}
