#!/usr/bin/env bash

[[ -n "${CONFIG_DIR:-}" && -r "$CONFIG_DIR/globalstyles.sh" ]] && source "$CONFIG_DIR/globalstyles.sh"

: "${NAME:=dndindicator}"
: "${ICON_DND_ON:=􀆺}"
: "${ICON_COLOR:=0xffffffff}"

DND_DB="$HOME/Library/DoNotDisturb/DB/Assertions.json"
SENDER_FILE="${TMPDIR:-/tmp}/sketchybar-${UID}-sender"

DND_STATE="focus_off"

set_state_from_event() {
  case "${DND_STATE_OVERRIDE:-${STATE:-${INFO:-${SENDER:-}}}}" in
    focus_on|on|true|1)
      DND_STATE="focus_on"
      return 0
      ;;
    focus_off|off|false|0)
      DND_STATE="focus_off"
      return 0
      ;;
  esac

  return 1
}

set_state_from_file() {
  case "$(cat "$SENDER_FILE" 2>/dev/null)" in
    focus_on)
      DND_STATE="focus_on"
      ;;
    *)
      DND_STATE="focus_off"
      ;;
  esac
}

check_state() {
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
      DND_STATE="focus_on"
    else
      DND_STATE="focus_off"
    fi
  else
    set_state_from_file
  fi
}

update_indicator() {
  if [[ "$DND_STATE" == "focus_on" ]]; then
    sketchybar --set "$NAME" \
      drawing=on \
      icon="$ICON_DND_ON" \
      icon.color="$ICON_COLOR" \
      label.drawing=off
  else
    sketchybar --set "$NAME" \
      drawing=off \
      icon="" \
      label.drawing=off
  fi
}

case "${SENDER:-}" in
  focus_on|focus_off)
    set_state_from_event || set_state_from_file
    ;;

  routine|forced)
    check_state
    ;;

  *)
    set_state_from_event || set_state_from_file
    ;;
esac

update_indicator
