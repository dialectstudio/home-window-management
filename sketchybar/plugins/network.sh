#!/usr/bin/env bash

# SketchyBar network plugin.
# Purpose: report the interface used by the default route.

set -u

item_name="${NAME:-network}"

trim() {
  awk '{$1=$1; print}' <<<"$*"
}

service_for_device() {
  local dev="$1"
  /usr/sbin/networksetup -listallhardwareports 2>/dev/null | awk -v dev="$dev" '
    /^Hardware Port: / { port=substr($0, 16) }
    /^Device: / { if ($2 == dev) { print port; exit } }
  '
}

wifi_ssid() {
  local dev="${1:-en0}"
  local ssid=""

  ssid=$(/usr/sbin/networksetup -getairportnetwork "$dev" 2>/dev/null \
    | sed -E 's/^Current Wi-Fi Network: //; s/^You are not associated with an AirPort network\.//')

  if [[ -z "$ssid" || "$ssid" == *"not associated"* ]]; then
    ssid=$(/usr/sbin/ipconfig getsummary "$dev" 2>/dev/null \
      | awk -F ' SSID : ' '/ SSID : / { print $2; exit }')
  fi

  trim "$ssid"
}

default_if=$(/sbin/route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')

if [[ -z "${default_if:-}" ]]; then
  sketchybar --set "$item_name" icon="×" label="offline"
  exit 0
fi

service=$(service_for_device "$default_if")
service=${service:-$default_if}
ip=$(/usr/sbin/ipconfig getifaddr "$default_if" 2>/dev/null || true)
status=$(/sbin/ifconfig "$default_if" 2>/dev/null | awk '/status:/{print $2; exit}')

case "$default_if:$service" in
  *:"Thunderbolt Ethernet"*|*:"USB Ethernet"*|*:"USB "*" LAN"*)
    icon="⛓"
    label="$service"
    ;;
  *:"Wi-Fi"*)
    icon="≋"
    ssid=$(wifi_ssid "$default_if")
    label=${ssid:-Wi-Fi}
    ;;
  bridge*:*)
    icon="⬡"
    label="Bridge"
    ;;
  *)
    icon="↔"
    label="$service"
    ;;
esac

if [[ "$status" == "inactive" || -z "$ip" ]]; then
  sketchybar --set "$item_name" icon="×" label="$label"
else
  sketchybar --set "$item_name" icon="$icon" label="$label"
fi
