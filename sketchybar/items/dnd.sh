#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
PLUGIN_DIR="${PLUGIN_DIR:-$CONFIG_DIR/plugins}"

sketchybar --add item dnd right

sketchybar --set dnd \
  script="$PLUGIN_DIR/dnd.sh" \
  label.drawing=off \
  icon="${ICON_DND_ON:-􀆺}" \
  drawing=off \
  updates=on

sketchybar --subscribe dnd \
  focus_on \
  focus_off \
  mouse.clicked
