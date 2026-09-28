#!/usr/bin/env bash

# Load global styles, colors and icons
source "$CONFIG_DIR/globalstyles.sh"

SID="$1"
ITEM="space.$SID"

space_icon() {
  case "$1" in
    1) echo "$ICON_HOMEAUTOMATION" ;;  # Home
    2) echo "$ICON_NOTE" ;;            # Writing
    3) echo "$ICON_BOOK" ;;            # Reading
    4) echo "$ICON_BOOKINFO" ;;        # Research
    5) echo "$ICON_DEV" ;;             # Development
    6) echo "$ICON_CHART" ;;           # MIS
    7) echo "$ICON_CHAT" ;;            # Mail/Messages
    8) echo "$ICON_VIDEOCHAT" ;;       # Meet
    9) echo "$ICON_REMOTEDESKTOP" ;;   # VM
    *) echo "$ICON_APP" ;;
  esac
}

app_icons_for_space() {
  local QUERY APPS LABEL APP BADGE

  QUERY="$(yabai -m query --windows --space "$SID" 2>/dev/null)"
  [[ -n "$QUERY" ]] || return

  IFS=$'\n'
  APPS=($(echo "$QUERY" | jq -r '.[].app' | sort -u))
  unset IFS

  for APP in "${APPS[@]}"; do
    [[ -n "$APP" ]] || continue

    LABEL+="$("$HOME/.config/sketchybar/plugins/app-icon.sh" "$APP")"

    BADGE="$(set_badge "$APP")"
    if [[ -n "$BADGE" ]]; then
      LABEL+=" $BADGE"
    fi

    LABEL+=" "
  done

  # Trim trailing whitespace
  LABEL="${LABEL%"${LABEL##*[![:space:]]}"}"

  echo "$LABEL"
}

set_badge() {
  local APP="$1"
  local BADGE

  if [[ "$APP" == "Messages" ]]; then
    BADGE="$(sqlite3 ~/Library/Messages/chat.db \
      "SELECT COUNT(guid) FROM message WHERE NOT(is_read) AND NOT(is_from_me) AND text !=''" 2>/dev/null)"
  else
    BADGE="$(lsappinfo -all info -only StatusLabel "$APP" 2>/dev/null \
      | sed -En 's/\"StatusLabel\"=\{ \"label\"=\"(.+)\" \}$/\1/p')"
  fi

  if [[ -z "$BADGE" ]]; then
    echo ""
  elif [[ ! "$BADGE" =~ ^[0-9]+$ ]]; then
    echo "􀍡"
  elif (( BADGE < 10 )); then
    ICONS=("" 􀀺 􀀼 􀀾 􀁀 􀁂 􀁄 􀁆 􀁈 􀁊)
    echo "${ICONS[$BADGE]}"
  else
    echo "􀍡"
  fi
}

update_space() {
  local CURRENT_SID SPACE_ICON APP_LABEL FULL_LABEL
  local BACKGROUND_COLOR COLOR STYLE

  CURRENT_SID="$(yabai -m query --spaces --space | jq -r '.index')"

  SPACE_ICON="$(space_icon "$SID")"
  APP_LABEL="$(app_icons_for_space)"

  if [[ -n "$APP_LABEL" ]]; then
    FULL_LABEL="$SPACE_ICON  $APP_LABEL"
  else
    FULL_LABEL="$SPACE_ICON"
  fi

  if [[ "$CURRENT_SID" == "$SID" ]]; then
    BACKGROUND_COLOR="$HIGHLIGHT"
    COLOR="$BAR_COLOR"
    STYLE="Bold"
  else
    BACKGROUND_COLOR="$(getcolor white 10)"
    COLOR="$LABEL_COLOR"
    STYLE="Regular"
  fi

  sketchybar --animate tanh 10                           \
             --set "$ITEM"                               \
                    label="$FULL_LABEL"                  \
                    icon.color="$COLOR"                  \
                    label.color="$COLOR"                 \
                    background.color="$BACKGROUND_COLOR" \
                    background.height=18                 \
                    icon.font.style="$STYLE"             \
                    label.font.style="$STYLE"
}

mouse_clicked() {
  if [[ "$MODIFIER" == "cmd" ]]; then
    "$HOME/.config/yabai/scripts/cycle-window.zsh" prev
  else
    yabai -m space --focus "$SID"
  fi
}

case "$SENDER" in
  "mouse.clicked")
    mouse_clicked
    ;;
  *)
    update_space
    ;;
esac
