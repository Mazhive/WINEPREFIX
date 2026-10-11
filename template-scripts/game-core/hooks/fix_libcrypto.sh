#!/bin/bash
# hook: fix-libcrypto — Fix missing libcrypto.so.1.1, libssl.so.1.1 and GStreamer libs on systems with OpenSSL 3
#
# On modern distros (Debian 12+, Ubuntu 22.04+, Arch/CachyOS), libcrypto.so.1.1/libssl.so.1.1 are missing
# but Steam runtime provides them. This hook finds them recursively in Steam runtime dirs
# and symlinks to ~/.local/lib/ + sets LD_LIBRARY_PATH.

hook_run() {
  local libs=("libcrypto.so.1.1" "libssl.so.1.1" "libFLAC.so.8" "libwebp.so.6" "libvpx.so.6")
  local local_lib="$HOME/.local/lib"
  mkdir -p "$local_lib"

  # Steam runtime root directories (cross-distro) for libcrypto/libssl
  local steam_roots=(
    "$HOME/.steam/debian-installation"      # Debian/Ubuntu
    "$HOME/.steam/steam"                    # Symlink
    "$HOME/.local/share/Steam"              # Arch/CachyOS/Fedora/etc
    "$HOME/.local/share/Steam/steamrt64"    # Steam runtime 64
    "/usr/lib/steam-runtime"                # System-installed
    "/usr/lib32/steam-runtime"
  )

  # Known paths for GStreamer libs (Arch/CachyOS Steam runtime)
  local gstreamer_paths=(
    "$HOME/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/x86_64-linux-gnu"
    "$HOME/.local/share/Steam/ubuntu12_64/steam-runtime/usr/lib/x86_64-linux-gnu"
    "$HOME/.local/share/Steam/steamrt64/pv-runtime/steam-runtime-steamrt/var/tmp-*/usr/lib/x86_64-linux-gnu"
    "$HOME/.local/share/Steam/steamapps/common/SteamLinuxRuntime/steam-runtime/usr/lib/x86_64-linux-gnu"
    "$HOME/.local/share/Steam/steamrt64/pv-runtime/steam-runtime-steamrt/steamrt3c_platform_*/files/lib/x86_64-linux-gnu"
  )

  for lib in "${libs[@]}"; do
    # Check if already available system-wide
    if ldconfig -p 2>/dev/null | grep -q "$lib" || \
       [ -f "/usr/lib/x86_64-linux-gnu/$lib" ] || \
       [ -f "/lib/x86_64-linux-gnu/$lib" ] || \
       [ -f "/usr/lib/$lib" ] || \
       [ -f "/lib/$lib" ]; then
      _log "hook(fix-libcrypto): $lib already available system-wide"
      continue
    fi

    local found=""

    # For GStreamer libs, check known paths first
    if [[ "$lib" == "libFLAC.so.8" || "$lib" == "libwebp.so.6" || "$lib" == "libvpx.so.6" ]]; then
      for path in "${gstreamer_paths[@]}"; do
        # Expand wildcards
        for expanded in $path; do
          if [ -f "$expanded/$lib" ]; then
            found="$expanded/$lib"
            break 2
          fi
        done
      done
    fi

    # For libcrypto/libssl, search recursively in steam_roots
    if [ -z "$found" ]; then
      for root in "${steam_roots[@]}"; do
        [ -d "$root" ] || continue
        # Use find with head to avoid subshell issues
        found=$(find "$root" -type f -name "$lib" -print 2>/dev/null | head -1)
        [ -n "$found" ] && break
      done
    fi

    if [ -z "$found" ]; then
      _log "hook(fix-libcrypto): $lib not found in Steam runtime"
      continue
    fi

    # Symlink to local lib dir
    if [ ! -f "$local_lib/$lib" ] || [ ! -L "$local_lib/$lib" ]; then
      ln -sf "$found" "$local_lib/$lib" 2>/dev/null && \
        _log "hook(fix-libcrypto): Symlinked $lib from $(dirname "$found") to $local_lib/"
    fi
  done

  export LD_LIBRARY_PATH="$local_lib:${LD_LIBRARY_PATH:-}"
  _log "hook(fix-libcrypto): LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
}
