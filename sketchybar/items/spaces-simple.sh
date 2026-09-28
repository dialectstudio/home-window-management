#!/usr/bin/env bash

# ~/.config/sketchybar/items/spaces-simple.sh
#
# Build SketchyBar space components from yabai's canonical workspace model.

spaces=(
  updates=on
  background.height=16
  icon.padding_left=$PADDINGS
  icon.padding_right=$PADDINGS
  label.drawing=off
  label.padding_left=0
  label.padding_right=$PADDINGS
)

WORKSPACES_FILE="$HOME/.config/yabai/workspaces.tsv"
SPACE_ICONS=(
  "$ICON_HOMEAUTOMATION" "$ICON_PEN" "$ICON_READING" "$ICON_RESEARCH"
  "$ICON_DEV2" "$ICON_CHART" "$ICON_CHAT" "$ICON_VIDEOCHAT" "$ICON_PLAY"
)
SPACE_COLORS=(cyan orange green maroon yellow red purple blue blue)

if [[ ! -r "$WORKSPACES_FILE" ]]; then
  printf 'sketchybar: workspace model not found: %s\n' "$WORKSPACES_FILE" >&2
  return 1
fi

while IFS=$'\t' read -r MODEL_INDEX SPACE_LABEL SPACE_LAYOUT DEFAULT_APP PLACEMENT_APPS; do
  SPACE_ICON=${SPACE_ICONS[$((MODEL_INDEX - 1))]}
  COLOR_NAME=${SPACE_COLORS[$((MODEL_INDEX - 1))]}

  SID=$(
    /usr/local/bin/yabai -m query --spaces label,index |
      /usr/local/bin/jq -r \
        --arg label "$SPACE_LABEL" \
        'first(.[] | select(.label == $label) | .index) // empty'
  )

  if [[ -z "$SID" ]]; then
    printf 'sketchybar: semantic space not found: %s\n' \
      "$SPACE_LABEL" >&2
    continue
  fi

  SPACE_COLOR=$(getcolor "$COLOR_NAME")

  sketchybar \
    --add space "space.$SID" left \
    --set "space.$SID" \
      "${spaces[@]}" \
      space="$SID" \
      icon="$SPACE_ICON" \
      icon.highlight_color="$SPACE_COLOR" \
      label.highlight_color="$SPACE_COLOR" \
      script="$PLUGIN_DIR/app-space-simple.sh $SID $SPACE_COLOR" \
    --subscribe "space.$SID" \
      mouse.clicked \
      space_change \
      space_windows_change \
      yabai_window_change \
      front_app_switched
done < "$WORKSPACES_FILE"
