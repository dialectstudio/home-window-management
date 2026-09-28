#!/usr/bin/env bash

# SketchyBar macOS Network Location plugin.

set -u

item_name="${NAME:-location}"
current=$(/usr/sbin/networksetup -getcurrentlocation 2>/dev/null | tr -d '\r')
current=${current:-Unknown}

case "$current" in
  Automatic)
    icon="⟳"
    label="Auto"
    ;;
  *)
    icon="⌖"
    label="$current"
    ;;
esac

sketchybar --set "$item_name" icon="$icon" label="$label"
