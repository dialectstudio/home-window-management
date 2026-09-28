#!/usr/bin/env bash

dndindicator=(
  icon="${ICON_DND_ON:-􀆺}"
  icon.color="$ICON_COLOR"
  label.drawing=off
  drawing=off
  update_freq=60
  script="$PLUGIN_DIR/dndindicator.sh"
  click_script="$PLUGIN_DIR/dnd.sh"
)

sketchybar --add item dndindicator right \
  --set dndindicator "${dndindicator[@]}" \
  --subscribe dndindicator focus_on focus_off
