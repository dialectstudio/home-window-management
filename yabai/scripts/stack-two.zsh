#!/bin/zsh

# ~/.config/yabai/scripts/stack-two.zsh
#
# Usage:
#   stack-two.zsh west|east|north|south
#
# Stack the directional neighbour with the focused window, but only
# when neither window is already a member of a stack. This limits
# stacks created by this helper to two windows.

emulate -LR zsh
setopt nounset pipefail

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

[[ -x $YABAI ]] || {
  print -ru2 -- "stack-two: yabai not found: $YABAI"
  exit 69
}

[[ -x $JQ ]] || {
  print -ru2 -- "stack-two: jq not found: $JQ"
  exit 69
}

typeset direction=${1:-}

case $direction in
  west|east|north|south)
    ;;
  *)
    print -ru2 -- "usage: ${0:t} west|east|north|south"
    exit 64
    ;;
esac

typeset focused_json target_json
typeset focused_id target_id
typeset -i focused_stack target_stack

focused_json=$(
  "$YABAI" -m query --windows id,stack-index --window 2>/dev/null
) || exit 0

target_json=$(
  "$YABAI" -m query --windows id,stack-index --window "$direction" 2>/dev/null
) || exit 0

focused_id=$(print -r -- "$focused_json" | "$JQ" -re '.id') || exit 0
target_id=$(print -r -- "$target_json" | "$JQ" -re '.id') || exit 0

focused_stack=$(
  print -r -- "$focused_json" |
    "$JQ" -r '."stack-index" // 0'
)

target_stack=$(
  print -r -- "$target_json" |
    "$JQ" -r '."stack-index" // 0'
)

# Nothing useful to do if yabai resolved both selectors to one window.
[[ $focused_id != $target_id ]] || exit 0

# Do not enlarge an existing stack.
(( focused_stack == 0 && target_stack == 0 )) || exit 0

exec "$YABAI" -m window --stack "$direction"
