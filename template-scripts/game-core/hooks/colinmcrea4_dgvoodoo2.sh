#!/bin/bash
# hook: colinmcrea4-dgvoodoo2 — Installeer dgVoodoo2 voor DirectX 9 upscaling
#
# dgVoodoo2 is een DirectX wrapper die oude D3D9/D3D8/DDraw games laat draaien
# op moderne systemen met correcte upscaling (640x480 -> 1920x1080).
#
# Download: https://github.com/dege-dgvoodoo2/dgVoodoo2/releases
# Versie: 2.82 (laatste stabiele)

hook_run() {
  local dgvoodoo_version="2.82"
  local dgvoodoo_url="https://github.com/dege-dgvoodoo2/dgVoodoo2/releases/download/v${dgvoodoo_version}/dgVoodoo2_${dgvoodoo_version}.zip"
  local cache_dir="$HOME/.cache/winetricks/dgvoodoo2"
  local zip_file="$cache_dir/dgVoodoo2_${dgvoodoo_version}.zip"
  local extract_dir="$cache_dir/dgVoodoo2_${dgvoodoo_version}"
  local sys32="$PREFIX_PATH/drive_c/windows/system32"

  mkdir -p "$cache_dir"

  # Download als niet aanwezig
  if [ ! -f "$zip_file" ]; then
    _log "hook(colinmcrea4-dgvoodoo2): downloaden dgVoodoo2 ${dgvoodoo_version}..."
    if ! wget -q -O "$zip_file" "$dgvoodoo_url"; then
      _log "hook(colinmcrea4-dgvoodoo2): FOUT - download mislukt"
      return 1
    fi
  fi

  # Extract
  _log "hook(colinmcrea4-dgvoodoo2): uitpakken..."
  rm -rf "$extract_dir"
  unzip -q -o "$zip_file" -d "$extract_dir" || {
    _log "hook(colinmcrea4-dgvoodoo2): FOUT - unzip mislukt"
    return 1
  }

  # Kopieer 32-bit DLL's naar system32 (win32 prefix)
  # dgVoodoo2 structuur: MS/x86/ voor 32-bit
  local src_dir="$extract_dir/MS/x86"
  if [ ! -d "$src_dir" ]; then
    # Oudere versies hebben andere structuur
    src_dir=$(find "$extract_dir" -name "d3d9.dll" -type f | head -1 | xargs dirname)
  fi

  if [ ! -d "$src_dir" ]; then
    _log "hook(colinmcrea4-dgvoodoo2): FOUT - geen DLL's gevonden in archive"
    return 1
  fi

  _log "hook(colinmcrea4-dgvoodoo2): installeren DLL's naar $sys32"
  cp -f "$src_dir"/d3d9.dll "$sys32/" 2>/dev/null || true
  cp -f "$src_dir"/d3d8.dll "$sys32/" 2>/dev/null || true
  cp -f "$src_dir"/d3dimm.dll "$sys32/" 2>/dev/null || true
  cp -f "$src_dir"/d3dimm700.dll "$sys32/" 2>/dev/null || true
  cp -f "$src_dir"/ddraw.dll "$sys32/" 2>/dev/null || true
  cp -f "$src_dir"/dgVoodooCpl.dll "$sys32/" 2>/dev/null || true
  cp -f "$src_dir"/dgVoodoo.conf "$sys32/" 2>/dev/null || true

  # Maak dgVoodoo.conf voor Colin McRae 4 (640x480 -> 1920x1080 upscaling)
  cat > "$sys32/dgVoodoo.conf" <<'EOF'
[dgVoodoo]
Resolution=1920x1080
ScalingMode=stretched
EnumerateRefreshRates=false
ForceVSync=true
DisableAltTab=false
FastVideoMemoryAccess=true
DeviceMultiThreading=true

[DirectX]
D3D9=true
D3D8=true
DirectDraw=true
ForceDirectDrawEmulation=false
ForceDirect3D9Emulation=false
ForceDirect3D8Emulation=false

[Direct3D9]
Resolution=1920x1080
ScalingMode=stretched
EnumerateRefreshRates=false
ForceVSync=true
DisableAltTab=false
FastVideoMemoryAccess=true
DeviceMultiThreading=true

[Direct3D8]
Resolution=1920x1080
ScalingMode=stretched
EnumerateRefreshRates=false
ForceVSync=true

[DirectDraw]
Resolution=1920x1080
ScalingMode=stretched
EnumerateRefreshRates=false
ForceVSync=true

[Glide]
Resolution=1920x1080
ScalingMode=stretched
EOF

  _log "hook(colinmcrea4-dgvoodoo2): dgVoodoo2 ${dgvoodoo_version} geïnstalleerd met config voor 1920x1080 upscaling"
}