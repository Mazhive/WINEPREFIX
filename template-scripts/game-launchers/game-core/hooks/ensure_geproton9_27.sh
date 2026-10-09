#!/usr/bin/env bash
# ensure_geproton9_27.sh — Zorg dat GE-Proton9-27 beschikbaar is in compatibilitytools.d
#https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-27/GE-Proton9-27.tar.gz
hook_run() {
  local pin="GE-Proton9-27"
  local url="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${pin}/${pin}.tar.gz"
  local tmp="/tmp/${pin}.tar.gz"
  local roots=()

  # Zoek bestaande roots
  [ -d "$HOME/.config/heroic/tools/proton" ] && roots+=("$HOME/.config/heroic/tools/proton")
  while IFS= read -r dir; do
    [ -d "$dir/compatibilitytools.d" ] && roots+=("$dir/compatibilitytools.d")
  done < <(_steam_client_dirs 2>/dev/null || true)

  # Controleer of pin al bestaat
  for root in "${roots[@]}"; do
    [ -x "$root/$pin/proton" ] && return 0
  done

  # Kies eerste root om te installeren
  local target="${roots[0]:-$HOME/.steam/root/compatibilitytools.d}"
  mkdir -p "$target"

  echo "[ensure_geproton9_27] Downloaden $pin naar $target..."
  curl -L -o "$tmp" "$url" || wget -O "$tmp" "$url" || return 1
  tar -xzf "$tmp" -C "$target" || return 1
  rm -f "$tmp"
  chmod +x "$target/$pin/proton" 2>/dev/null || true
  echo "[ensure_geproton9_27] $pin geïnstalleerd in $target"
}
