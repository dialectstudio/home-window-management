#!/usr/bin/env bash

# ~/.config/sketchybar/plugins/app-space-simple.sh

source "$CONFIG_DIR/globalstyles.sh"

SID=$1
SPACE_COLOR=$2

PREV_SID=$(
  /usr/local/bin/yabai -m query --spaces --space recent 2>/dev/null |
    /usr/local/bin/jq -r '.index // empty'
)

CURRENT_SID=$(
  /usr/local/bin/yabai -m query --spaces index --space 2>/dev/null |
    /usr/local/bin/jq -r '.index // empty' 2>/dev/null
)

FOCUSED_APP=$(
  /usr/local/bin/yabai -m query --windows app --window 2>/dev/null |
    /usr/local/bin/jq -r '.app // empty'
)

update_colors() {
  if [[ "$SID" == "$PREV_SID" ]]; then
    sketchybar --animate tanh 20 \
      --set "space.$PREV_SID" \
        background.color="$TRANSPARENT" \
        icon.color="$ICON_COLOR" \
        label.color="$LABEL_COLOR"

  elif [[ "$SID" == "$CURRENT_SID" ]]; then
    sketchybar --animate tanh 20 \
      --set "space.$CURRENT_SID" \
        background.color="$SPACE_COLOR" \
        icon.color="$BAR_COLOR" \
        label.color="$BAR_COLOR"
  fi
}

update_label() {
  [[ "$SID" == "$CURRENT_SID" ]] || return 0

  if [[ -n "$FOCUSED_APP" ]]; then
    sketchybar --animate tanh 20 \
      --set "space.$CURRENT_SID" \
        label.drawing=on \
        label="$FOCUSED_APP"
  else
    sketchybar --set "space.$CURRENT_SID" \
      label.drawing=off
  fi
}

remove_label() {
  if [[ -n "$PREV_SID" && "$SID" == "$PREV_SID" ]]; then
    sketchybar --animate tanh 20 \
      --set "space.$PREV_SID" label.drawing=off
  fi
}

mouse_clicked() {
  # Workspace labels come from workspaces.tsv; clicks never rename them.
  if [[ "${BUTTON:-}" == right || "${MODIFIER:-}" == shift ]]; then
    return 0
  fi

  if [[ "$SID" != "$CURRENT_SID" ]]; then
    /usr/local/bin/yabai -m space --focus "$SID"
  else
    "$HOME/.config/yabai/scripts/cycle-window.zsh" prev
  fi
}

case "${SENDER:-}" in
  routine|forced|space_change|space_windows_change|yabai_window_change)
    update_colors
    update_label
    remove_label
    ;;

  front_app_switched)
    update_label
    ;;

  mouse.clicked)
    mouse_clicked
    ;;
esac
