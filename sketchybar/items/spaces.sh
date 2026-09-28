#!/usr/bin/env bash

# Load global styles, colors and icons
source "$CONFIG_DIR/globalstyles.sh"

# Defaults
spaces=(
  background.corner_radius=4
  background.height=18

  icon.font="$FONT:Regular:12"
  icon.padding_left=$PADDINGS
  icon.padding_right=3

  label.font="$FONT:Regular:18"
  label.padding_left=3
  label.padding_right=$PADDINGS
)

# Get all spaces
SPACES=($(yabai -m query --spaces index | jq -r '.[].index'))

for SID in "${SPACES[@]}"; do
  sketchybar --add space space.$SID left                  \
             --set space.$SID "${spaces[@]}"              \
                   script="$PLUGIN_DIR/app-space.sh $SID" \
                   associated_space=$SID                  \
                   icon="$SID"                            \
             --subscribe space.$SID                       \
                   mouse.clicked                          \
                   front_app_switched                     \
                   space_change                           \
                   space_windows_change
done
