#!/usr/bin/env bash

render_item() {
  # sketchybar --set $NAME label="$(date "+%I:%M %p")" \
  sketchybar --set $NAME label="$(date "+%H%M %Z")" \
             --set date icon.drawing=$DRAWING \
             --set clock label.padding_left=$PADDING
}

get_events() {
  local ical_buddy=/usr/local/bin/icalBuddy

  if [[ -x "$ical_buddy" ]]; then
    DRAWING="off"
    PADDING="0"
    input=$("$ical_buddy" -ec 'Found in Natural Language,CCSF' -npn -nc -iep 'datetime,title' -po 'datetime,title' -eed -ea -n -li 4 -ps '|: |' -b '' eventsToday 2>/dev/null)
    currentTime=$(date '+%I:%M %p')
    # currentTime=$(date '+%H%M %Z')

    if [ -n "$input" ]; then
      IFS='^' read -ra events <<< "$input"
      for anEvent in "${events[@]}"; do
        IFS='^' read -ra eventItems <<< "$anEvent"
        eventTime=${eventItems[0]}
        if [ "$eventTime" '>' "$currentTime" ]; then
          theEvent="$anEvent"
          if [ "$(cat "${TMPDIR:-/tmp}/sketchybar-${UID}-sender" 2>/dev/null)" = "focus_off" ]; then
            DRAWING="on"
          fi
          PADDING="12"
          break
        fi
      done
    else
      theEvent="No events today"
    fi
  else
    theEvent="Please install icalBuddy → brew install ical-buddy."
  fi
}

update() {
  get_events
  render_item
}

popup() {
  get_events
  sketchybar --set clock.next_event label="$theEvent" \
             --set "$NAME" popup.drawing="$1"
}

case "$SENDER" in
"routine" | "forced" | "focus_on" | "focus_off")
  update
  ;;
"mouse.entered")
  popup on
  ;;
"mouse.exited" | "mouse.exited.global")
  popup off
  ;;
esac
