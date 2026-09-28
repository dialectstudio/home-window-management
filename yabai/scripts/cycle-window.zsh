#!/bin/zsh

# ~/.config/yabai/scripts/cycle-window.zsh
#
# Cycle through usable windows on the current space according to
# their physical position rather than yabai's BSP tree order.
#
# Usage:
#   cycle-window.zsh prev
#   cycle-window.zsh next
#
# Default:
#   prev

emulate -LR zsh
setopt nounset pipefail

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

[[ -x $YABAI ]] || {
  print -ru2 -- "cycle-window: yabai not found: $YABAI"
  exit 69
}

[[ -x $JQ ]] || {
  print -ru2 -- "cycle-window: jq not found: $JQ"
  exit 69
}

typeset direction=${1:-prev}

case $direction in
  prev|next)
    ;;
  *)
    print -ru2 -- "usage: ${0:t} prev|next"
    exit 64
    ;;
esac

typeset windows_json target_id

windows_json=$(
  "$YABAI" -m query --windows --space 2>/dev/null
) || {
  print -ru2 -- "cycle-window: could not query current space"
  exit 1
}

target_id=$(
  print -r -- "$windows_json" |
    "$JQ" -er --arg direction "$direction" '
      map(
        select(
          .["is-minimized"] == false and
          .["is-hidden"] == false and
          .["has-ax-reference"] == true
        )
      )
      | sort_by(.display, .frame.y, .frame.x, .id)
      | . as $wins
      | ($wins | length) as $count
      | ($wins | map(.["has-focus"]) | index(true)) as $focused

      | if $count == 0 then
          empty

        elif $focused == null then
          if $direction == "next"
          then $wins[0].id
          else $wins[$count - 1].id
          end

        elif $direction == "next" then
          $wins[(($focused + 1) % $count)].id

        else
          $wins[
            if $focused == 0
            then $count - 1
            else $focused - 1
            end
          ].id
        end
    '
) || exit 0

[[ -n $target_id ]] || exit 0

exec "$YABAI" -m window --focus "$target_id"
