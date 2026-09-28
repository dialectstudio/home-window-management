#!/usr/bin/env bash

# Right-side macOS Network Location item with a popup selector.

sketchybar --add item location right \
  --set location \
    update_freq=30 \
    icon="⌖" \
    label="Location" \
    script="$PLUGIN_DIR/location.sh" \
    click_script="sketchybar --set location popup.drawing=toggle" \
    popup.align=right \
  --subscribe location system_woke network_location_changed

location_index=0
while IFS= read -r location_name; do
  [[ -n "$location_name" ]] || continue
  printf -v quoted_location '%q' "$location_name"

  sketchybar --add item "location.$location_index" popup.location \
    --set "location.$location_index" \
      icon="⌖" \
      label="$location_name" \
      click_script="$PLUGIN_DIR/location_click.sh $quoted_location"

  ((location_index += 1))
done < <(/usr/sbin/networksetup -listlocations 2>/dev/null)
