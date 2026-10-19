#!/bin/bash
# hook: install_emu — installeer één emulator voor GAME_SYSTEM.
#
# Draait via EMU-LAUNCHERS/emu-install.sh (sourcet game-common.sh voor _log/
# _busy_* en roept _run_hook install_emu aan). Verwacht in de omgeving:
#   GAME_SYSTEM   = systeem-sleutel (sectie in emulation.conf)
#   EMU_CONF      = actieve emulation.conf (home-versie)
#   EMU_REPO_CONF = repo-sjabloon (fallback voor url/gh_repo-velden)
#
# Werkwijze per systeem-sectie:
#   detect → ask-yesno.sh → downloaden → uitpakken → chmod +x → conf bijwerken
#
# Conf-velden (in de sectie):
#   emu=          doelpad van de emulator (verplicht; leeg mag, dan EMU_ROOT)
#   url=          directe download-URL
#   gh_repo=      owner/naam → nieuwste release-asset via de GitHub-API
#   asset_glob=   glob om de juiste asset te kiezen (default *x86_64.AppImage)
#   member=       pad/naam in het archief (bij .zip/.7z)
#   core_url=     optioneel: libretro-core (.zip) voor de -L-route
#   core_member=  naam van de core in het archief

EMU_ROOT="${EMU_ROOT:-/mnt/VG_00/Portable.APPS/EMU}"

_conf_get() {
  # _conf_get <bestand> <key> → waarde binnen sectie [$SYS]
  local file="$1" key="$2"
  [ -f "$file" ] || return 0
  awk -v s="[$SYS]" -v k="$key" \
      'BEGIN{f=0} /^\[/{f=($0==s)} f && index($0,k"=")==1 {print substr($0,length(k)+2); exit}' \
      "$file"
}

_conf_merged() {
  # Waarde uit de actieve conf; valt terug op het repo-sjabloon.
  local key="$1" val
  val="$(_conf_get "$EMU_CONF" "$key")"
  [ -n "$val" ] || val="$(_conf_get "$EMU_REPO_CONF" "$key")"
  printf '%s' "$val"
}

_asset_from_github() {
  # _asset_from_github <repo> <glob> → browser_download_url
  local repo="$1" glob="$2" re api
  command -v jq >/dev/null 2>&1 || return 1
  [ -n "$glob" ] || glob="*x86_64.AppImage"
  re="$(printf '%s' "$glob" | sed 's/[.[\^$+?(){}|]/\\&/g; s/\*/.*/g')"
  api="https://api.github.com/repos/$repo/releases/latest"
  curl -fsSL "$api" 2>/dev/null \
    | jq -r --arg re "$re" '.assets[] | select(.name|test($re)) | .browser_download_url' 2>/dev/null \
    | head -1
}

_download() {
  # _download <url> <dest>
  local url="$1" dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --connect-timeout 20 -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$dest" "$url"
  else
    _log "hook(install_emu): geen curl/wget beschikbaar."
    return 1
  fi
}

_extract_member() {
  # _extract_member <archief> <member> <dest>
  local arc="$1" member="$2" dest="$3"
  case "$arc" in
    *.zip)
      unzip -p "$arc" "$member" > "$dest" 2>/dev/null || return 1 ;;
    *.7z)
      7z x -so "$arc" "$member" > "$dest" 2>/dev/null || return 1 ;;
    *)
      cp -f "$arc" "$dest" || return 1 ;;
  esac
}

_conf_set() {
  # _conf_set <key> <value> → werk de actieve conf bij (indien schrijfbaar)
  local key="$1" val="$2" tmp
  [ -w "$EMU_CONF" ] || return 0
  tmp="$(mktemp)"
  awk -v s="$SYS" -v k="$key" -v v="$val" \
      'BEGIN{f=0} /^\[/{f=($0=="["s"]")} f && index($0,k"=")==1 {print k"="v; next} {print}' \
      "$EMU_CONF" > "$tmp" && mv "$tmp" "$EMU_CONF" || rm -f "$tmp"
}

_install_core() {
  # Optionele libretro-core voor RetroArch-systemen.
  local core_url core_member core_path tmp
  core_url="$(_conf_merged core_url)"
  [ -n "$core_url" ] || return 0
  core_member="$(_conf_merged core_member)"
  core_path="$(printf '%s\n' "$args" | awk '{for(i=1;i<=NF;i++) if($i=="-L"){print $(i+1)}}')"
  [ -n "$core_path" ] || { _log "hook(install_emu): core_url gezet maar geen -L-pad in args."; return 1; }
  [ -e "$core_path" ] && return 0
  _log "hook(install_emu): libretro-core ophalen → $core_path"
  mkdir -p "$(dirname "$core_path")"
  tmp="$(mktemp)"
  _download "$core_url" "$tmp" || { rm -f "$tmp"; return 1; }
  _extract_member "$tmp" "$core_member" "$core_path" || { rm -f "$tmp"; return 1; }
  rm -f "$tmp"
  chmod +x "$core_path" 2>/dev/null || true
}

hook_run() {
  local SYS="${GAME_SYSTEM:-}"
  [ -n "$SYS" ] || { _log "hook(install_emu): GAME_SYSTEM niet gezet."; return 1; }

  local title emu args url gh_repo asset_glob member
  title="$(_conf_merged title)"; [ -n "$title" ] || title="$SYS"
  emu="$(_conf_merged emu)"
  args="$(_conf_merged args)"
  url="$(_conf_merged url)"
  gh_repo="$(_conf_merged gh_repo)"
  asset_glob="$(_conf_merged asset_glob)"
  member="$(_conf_merged member)"

  # Al aanwezig? Klaar.
  if [ -n "$emu" ] && [ -e "$emu" ]; then
    _log "hook(install_emu): $title al aanwezig ($emu)."
    _conf_set status ok
    _install_core
    return 0
  fi

  # Download-URL bepalen.
  if [ -z "$url" ] && [ -n "$gh_repo" ]; then
    _log "hook(install_emu): nieuwste release opzoeken voor $gh_repo"
    url="$(_asset_from_github "$gh_repo" "$asset_glob")"
  fi
  [ -n "$url" ] || {
    _log "hook(install_emu): geen downloadbron voor [$SYS] (zet url= of gh_repo=)."
    _log "hook(install_emu): koppel de emulator handmatig in $EMU_CONF."
    return 1
  }

  if [ -z "$emu" ]; then
    emu="$EMU_ROOT/$SYS/$(basename "$url")"
    _log "hook(install_emu): geen emu= in conf; doel wordt $emu"
  fi

  # Bevestiging vragen (CLI- en desktop-veilig).
  local ask="$HOOKS_DIR/../tools/ask-yesno.sh"
  if [ -x "$ask" ]; then
    if ! "$ask" --title "$title installeren" \
         --message "$title is nog niet geïnstalleerd.\n\nDownloaden naar:\n$emu\n\nNu installeren?"; then
      _log "hook(install_emu): installatie van $title geannuleerd."
      return 1
    fi
  fi

  mkdir -p "$(dirname "$emu")"
  local tmp
  tmp="$(mktemp)"
  _log "hook(install_emu): downloaden: $url"
  if ! _download "$url" "$tmp"; then
    rm -f "$tmp"
    _log "hook(install_emu): download mislukt: $url"
    return 1
  fi

  case "$url" in
    *.zip|*.7z)
      [ -n "$member" ] || member="$(basename "$emu")"
      _extract_member "$tmp" "$member" "$emu" || {
        rm -f "$tmp"
        _log "hook(install_emu): kon '$member' niet uit het archief halen."
        return 1
      }
      ;;
    *)
      mv -f "$tmp" "$emu"
      ;;
  esac
  rm -f "$tmp"
  chmod +x "$emu" 2>/dev/null || true

  if [ ! -e "$emu" ]; then
    _log "hook(install_emu): doelpad niet aangemaakt: $emu"
    return 1
  fi

  _conf_set emu "$emu"
  _conf_set status ok
  _install_core
  _log "hook(install_emu): $title geïnstalleerd → $emu"
  return 0
}
