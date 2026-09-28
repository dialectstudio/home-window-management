#!/usr/bin/env bash

# Right-side weather item. Uses WeatherAPI.com via ~/.dotfiles/secrets/weather by default.

sketchybar --add item weather right \
  --set weather \
    update_freq=900 \
    icon="☁" \
    label="--°" \
    script="$PLUGIN_DIR/weather.sh" \
    click_script="open -a Weather" \
  --subscribe weather system_woke network_location_changed
