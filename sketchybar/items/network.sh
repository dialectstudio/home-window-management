#!/usr/bin/env bash

# Right-side network status item.
# Shows the active default-route interface, not merely whether Wi-Fi is associated.

sketchybar --add item network right \
  --set network \
    update_freq=10 \
    icon="↔" \
    label="net" \
    script="$PLUGIN_DIR/network.sh" \
    click_script="open -a 'System Settings'" \
  --subscribe network system_woke network_location_changed
