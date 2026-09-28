#!/bin/zsh

# ~/.config/yabai/scripts/window-resize.zsh
#
# Grow or shrink the focused BSP-managed window while accounting for
# whether it is the first or second child of its current split.
#
# Usage:
#   window-resize.zsh increase [pixels]
#   window-resize.zsh decrease [pixels]
#
# Short forms:
#   window-resize.zsh + [pixels]
#   window-resize.zsh - [pixels]
#
# Default amount:
#   100 pixels

emulate -LR zsh
setopt nounset pipefail

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

[[ -x $YABAI ]] || {
  print -ru2 -- "window-resize: yabai not found: $YABAI"
  exit 69
}

[[ -x $JQ ]] || {
  print -ru2 -- "window-resize: jq not found: $JQ"
  exit 69
}

typeset action=${1:-}
typeset amount=${2:-100}

[[ $amount == <-> ]] && (( amount > 0 )) || {
  print -ru2 -- "window-resize: pixel amount must be a positive integer"
  exit 64
}

typeset -i delta

case $action in
  increase|+|grow)
    delta=$amount
    ;;
  decrease|-|shrink)
    delta=$((-amount))
    ;;
  *)
    print -ru2 -- "usage: ${0:t} increase|decrease [pixels]"
    exit 64
    ;;
esac

typeset window_json values
typeset split_type split_child is_floating

window_json=$(
  "$YABAI" -m query --windows \
    split-type,split-child,is-floating \
    --window 2>/dev/null
) || {
  print -ru2 -- "window-resize: no focused yabai window"
  exit 1
}

values=$(
  print -r -- "$window_json" |
    "$JQ" -r '
      [
        .["split-type"],
        .["split-child"],
        .["is-floating"]
      ]
      | @tsv
    '
)

IFS=$'\t' read -r \
  split_type \
  split_child \
  is_floating <<< "$values"

[[ $is_floating == false ]] || {
  print -ru2 -- "window-resize: focused window is floating"
  exit 1
}

typeset resize_spec

case "$split_type:$split_child" in
  vertical:first_child)
    resize_spec="right:${delta}:0"
    ;;

  vertical:second_child)
    resize_spec="left:$((-delta)):0"
    ;;

  horizontal:first_child)
    resize_spec="bottom:0:${delta}"
    ;;

  horizontal:second_child)
    resize_spec="top:0:$((-delta))"
    ;;

  *)
    print -ru2 -- \
      "window-resize: focused window has no adjustable BSP parent split"
    exit 1
    ;;
esac

exec "$YABAI" -m window --resize "$resize_spec"
