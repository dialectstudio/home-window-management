#!/usr/bin/env bash

# Load global styles, colors and icons
source "$CONFIG_DIR/globalstyles.sh"
source "$CONFIG_DIR/log.sh"

BREW=/usr/local/bin/brew
OUTDATED=$($BREW outdated 2>/dev/null)
COUNT=$(echo $OUTDATED | wc -w | tr -d ' ')

update_label() {
  DRAWING=$([ "$(cat "${TMPDIR:-/tmp}/sketchybar-${UID}-sender" 2>/dev/null)" == "focus_on" ] && echo "off" || echo "on")

  case "$COUNT" in
  [7-9] | [1-9][0-9])
    COLOR=$(getcolor red)
    ;;
  [3-6])
    COLOR=$(getcolor orange)
    ;;
  [1-2])
    COLOR=$(getcolor yellow)
    ;;
  0 | "")
    COLOR=$LABEL_COLOR
    DRAWING="off"
    ;;
  esac

  sketchybar --animate tanh 20 --set $NAME drawing=$DRAWING label=$COUNT icon.color=$COLOR
}

mouse_clicked() {
  sketchybar --set $NAME icon=$ICON_REFRESH
  if [[ -x /usr/local/bin/terminal-notifier ]]; then
    /usr/local/bin/terminal-notifier -title "$NAME" -subtitle "$COUNT outdated packages" -message "$OUTDATED"
  else
    sketchybar_log warn "terminal-notifier is unavailable; continuing brew update"
  fi

  if "$PLUGIN_DIR/brew-update.sh"; then
    sketchybar_log info "brew update and upgrade completed"
  else
    sketchybar_log error "brew update or upgrade failed"
  fi

  OUTDATED=$($BREW outdated 2>/dev/null)
  COUNT=$(echo "$OUTDATED" | wc -w | tr -d ' ')
  sleep 3
  update_label
  sketchybar --set $NAME icon=$ICON_PACKAGE
}

case "$SENDER" in
"routine" | "forced")
  update_label
  ;;
"mouse.clicked")
  mouse_clicked
  ;;
esac
