#!/bin/bash
# tools/gamepad-status.sh — read-only status van de gamepad-routes.
#
# Heeft GEEN root nodig. Rapporteert voor de pad (default 045e:028e):
#   - SDL/evdev-route (deze werkt zónder root; joystick zichtbaar voor
#     SDL/DInput-games zoals Crysis). Voeding via de ACL-lease van logind
#     (uaccess) op de js*/event*-nodes.
#   - XInput-route (wine bouwt dan een échte Xbox-controller uit hidraw;
#     nodig voor xinput-only-games zoals Ori/Cyberpunk). Vereist eenmalig:
#       1. udev-rule 70-pad-xinput.rules (MODE=0660 GROUP=input [uaccess])
#       2. gebruikers in de 'input'-groep   → usermod -aG input <user>
#       3. xpad niet laten claimen          → modprobe -r xpad + blacklist
#     Daarna is er géén root meer nodig op klikmoment.
#
# Env-overschrijvingen: PAD_VID, PAD_PID.
#
# Exit-codes: 0 = XInput-route klaar · 1 = pad niet aangesloten · 2 = pad
# aangesloten maar (nog) geen XInput-route (SDL-route kan wél werken).
set -u

PAD_VID="${PAD_VID:-045e}"
PAD_PID="${PAD_PID:-028e}"
PAD_USB_ATTR="045e:028e"               # lsusb-form {vid}:{pid}
UDEV_RULE_FILE="/etc/udev/rules.d/70-pad-xinput.rules"

say()   { printf '%s\n' "$*"; }
info()  { printf '%s\n' "  ... $*"; }
ok()    { printf '%s\n' "  ✓ $*"; }
note()  { printf '%s\n' "  - $*"; }

pad_usb() { lsusb -d "$PAD_VID:$PAD_PID" 2>/dev/null; }

xpad_loaded() { lsmod 2>/dev/null | grep -q '^xpad '; }

in_group_input() {
  id -nG 2>/dev/null | tr ' ' '\n' | grep -qx 'input'
}

# hidraw-node van de pad via udevadm (read-only). Ook ACL-leesbaarheid.
find_pad_node() {
  local h v m
  for h in /dev/hidraw*; do
    [ -e "$h" ] || continue
    v="$(udevadm info --query=property --name="$h" 2>/dev/null | sed -n 's/^ID_VENDOR_ID=//p' | head -1)"
    m="$(udevadm info --query=property --name="$h" 2>/dev/null | sed -n 's/^ID_MODEL_ID=//p' | head -1)"
    if [ "$v" = "$PAD_VID" ] && [ "$m" = "$PAD_PID" ]; then
      echo "$h"; return 0
    fi
  done
  return 1
}

cmd_status() {
  local rc=1
  say "pad  USB   : $(pad_usb || echo 'NIET aangesloten')"
  if ! pad_usb >/dev/null; then
    say "→ status : pad los of onbekend; steek de pad erin en draai opnieuw."
    return 1
  fi

  say "── SDL/evdev-route (werkt nú, zonder root) ──"
  local pad_js=""
  for js in /dev/input/js*; do
    [ -e "$js" ] || continue
    if udevadm info --query=property --name="$js" 2>/dev/null | grep -q "ID_INPUT_JOYSTICK=1"; then
      pad_js="$js"
    fi
  done
  if [ -n "$pad_js" ]; then
    local acl=""
    getfacl -p "$pad_js" 2>/dev/null | grep -q '^user:.*:rw' && acl=" (uaccess-ACL actief)"
    ok "js-node $pad_js $(stat -c '(%A)' "$pad_js")$acl → SDL-joystick voor DInput/SDL-games beschikbaar"
  else
    note "geen joystick-node zichtbaar voor deze gebruiker (evdev/js) — SDL-route onbeschikbaar"
  fi

  say "── XInput-route (wine bouwt échte Xbox-controller uit hidraw) ──"
  local node
  node="$(find_pad_node)" || node=""

  if xpad_loaded; then
    note "xpad-driver is GELADEN → claimt de pad; er is géén hidraw-node."
  else
    ok "xpad niet geladen — de pad is vrij voor usbhid/hidraw."
  fi

  if [ -f "$UDEV_RULE_FILE" ]; then
    ok "udev-rule $UDEV_RULE_FILE aanwezig"
  else
    note "udev-rule ontbreekt → permissie op de hidraw-node wordt nooit ingesteld."
  fi

  if in_group_input; then
    ok "gebruiker zit in de 'input'-groep."
  else
    note "gebruiker zit NIET in de 'input'-groep → hidraw-node blijft root-only (log opnieuw in na: usermod -aG input \$USER)."
  fi

  if [ -n "$node" ]; then
    if [ -r "$node" ]; then
      ok "pad hidraw $node $(stat -c '(%A)' "$node") → leesbaar; wine kan de pad als XInput-controller bouwen."
      rc=0
    else
      note "pad hidraw $node $(stat -c '(%A)' "$node") → NIET leesbaar voor deze gebruiker."
      rc=2
    fi
  else
    note "géén hidraw-node voor de pad (zie hierboven: xpad claimt 'm, of usbhid bindt niet)."
    rc=2
  fi

  if [ "$rc" -eq 0 ]; then
    say "→ status : XInput-route KLAAR — pad werkt in xinput-only-games zónder root."
  else
    say "→ status : XInput-route nog niet klaar. Eénmalige root-stappen:"
    say "     1. udev-rule + groepen:  sudo tools/pad-xinput-on.sh   (schrijft $UDEV_RULE_FILE)"
    say "     2. gebruikers in input:  sudo usermod -aG input \$USER   (dan opnieuw inloggen)"
    say "     3. xpad uitzetten:       sudo modprobe -r xpad           (blijvend: blacklist xpad)"
    say "     Daarna is er géén root meer nodig op klikmoment."
  fi
  return $rc
}

case "${1:-}" in
  status|"") cmd_status ;;
  -h|--help) sed -n '2,30p' "$0" ;;
  *) echo "gebruik: $0 [status]" >&2; exit 2 ;;
esac