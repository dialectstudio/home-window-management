#!/usr/bin/env bash

# Load global styles, colors and icons
[[ -n "${CONFIG_DIR:-}" && -r "$CONFIG_DIR/globalstyles.sh" ]] && source "$CONFIG_DIR/globalstyles.sh"

: "${NAME:=dnd}"
: "${ICON_COLOR:=0xffffffff}"
: "${ICON_COLOR_INACTIVE:=0xff777777}"
: "${ICON_DND_ON:=􀆺}"

DND_DB="$HOME/Library/DoNotDisturb/DB/Assertions.json"
STATE_FILE="${TMPDIR:-/tmp}/sketchybar-${UID}-state"
SENDER_FILE="${TMPDIR:-/tmp}/sketchybar-${UID}-sender"
INDICATOR_ITEM="${DND_INDICATOR_ITEM:-dndindicator}"

DND_STATE="focus_off"
COLOR="$ICON_COLOR_INACTIVE"

set_focus_on() {
  DND_STATE="focus_on"
  COLOR="$ICON_COLOR"
  printf '%s\n' "$DND_STATE" > "$SENDER_FILE"
}

set_focus_off() {
  DND_STATE="focus_off"
  COLOR="$ICON_COLOR_INACTIVE"
  printf '%s\n' "$DND_STATE" > "$SENDER_FILE"
}

check_state() {
  # Used only for routine/forced refreshes.
  # Event handlers below are authoritative because macOS has already told
  # SketchyBar whether DND was enabled or disabled.
  if [[ -r "$DND_DB" ]] && command -v jq >/dev/null 2>&1; then
    if jq -e '
      [
        .data[]?.storeAssertionRecords?
        | select(. != null)
        | if type == "array" then .[]
          elif type == "object" then .[]
          else empty
          end
        | select(. != null)
      ] | length > 0
    ' "$DND_DB" >/dev/null 2>&1; then
      set_focus_on
    else
      set_focus_off
    fi
  else
    # Conservative fallback: use last known state if available.
    case "$(cat "$SENDER_FILE" 2>/dev/null)" in
      focus_on)  set_focus_on ;;
      *)         set_focus_off ;;
    esac
  fi
}

get_items_to_hide() {
  local items=(
    "weather"
    "brew"
    "diskmonitor"
    "diskmonitor.value"
    "diskmonitor.label"
    "volume_icon"
    "volume"
    "notifications"
  )

  local current_space=""
  if command -v yabai >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    current_space="$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty' 2>/dev/null)"
  fi

#  for i in {1..8}; do
#    if [[ -z "$current_space" || "$i" != "$current_space" ]]; then
#      items+=("space.$i")
#    fi
#  done

  while IFS= read -r i; do
    if [[ -z "$current_space" || "$i" != "$current_space" ]]; then
      items+=("space.$i")
    fi
  done < <(
    /usr/local/bin/yabai -m query --spaces index 2>/dev/null |
      /usr/local/bin/jq -r '.[].index'
  )

  printf '%s\n' "${items[@]}"
}

sync_indicator() {
  sketchybar --query "$INDICATOR_ITEM" >/dev/null 2>&1 || return 0

  if [[ "$DND_STATE" == "focus_on" ]]; then
    sketchybar --set "$INDICATOR_ITEM" \
      drawing=on \
      icon="$ICON_DND_ON" \
      icon.color="$ICON_COLOR" \
      label.drawing=off
  else
    sketchybar --set "$INDICATOR_ITEM" \
      drawing=off \
      icon="" \
      label.drawing=off
  fi
}

update_icon() {
  local item state

  if [[ "$DND_STATE" == "focus_on" ]]; then
    # Snapshot only once. Repeated focus_on/routine events should not overwrite
    # the original visible/hidden state with already-hidden values.
    if [[ ! -s "$STATE_FILE" ]]; then
      : > "$STATE_FILE"

      while IFS= read -r item; do
        state="$(sketchybar --query "$item" 2>/dev/null | jq -r '.geometry.drawing // empty' 2>/dev/null)"
        if [[ "$state" == "on" || "$state" == "off" ]]; then
          printf '%s %s\n' "$item" "$state" >> "$STATE_FILE"
        fi
      done < <(get_items_to_hide)
    fi

    while IFS= read -r item; do
      sketchybar --set "$item" drawing=off >/dev/null 2>&1
    done < <(get_items_to_hide)

  else
    if [[ -r "$STATE_FILE" ]]; then
      while read -r item state; do
        if [[ "$state" == "on" ]]; then
          sketchybar --set "$item" drawing=on >/dev/null 2>&1
        fi
      done < "$STATE_FILE"

      rm -f "$STATE_FILE"
    fi
  fi

  sketchybar --set "$NAME" icon.color="$COLOR" >/dev/null 2>&1
  sync_indicator
}

toggle_dnd() {
  osascript -e 'tell application "System Events" to keystroke "\\" using {control down, shift down, command down, option down}'
}

case "${SENDER:-}" in
  "focus_on")
    set_focus_on
    update_icon
    ;;

  "focus_off")
    set_focus_off
    update_icon
    ;;

  "routine" | "forced")
    check_state
    update_icon
    ;;

  "mouse.clicked")
    toggle_dnd
    sleep 0.6
    check_state
    update_icon
    ;;

  *)
    check_state
    update_icon
    ;;
esac
