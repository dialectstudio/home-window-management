#!/usr/bin/env bash

# Switch macOS Network Location from a SketchyBar popup entry.

set -u

location="${1:-}"
[[ -n "$location" ]] || exit 1

if /usr/sbin/networksetup -switchtolocation "$location"; then
  sketchybar --set location popup.drawing=off
  sketchybar --trigger network_location_changed
else
  sketchybar --set location popup.drawing=off
  exit 1
fi
