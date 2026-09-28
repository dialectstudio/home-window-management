#!/bin/zsh

# ~/.config/yabai/scripts/space-thirds.zsh
#
# Adjust a usable BSP split on the current Space.
#
# Usage:
#   space-thirds.zsh left
#   space-thirds.zsh even
#   space-thirds.zsh balance
#   space-thirds.zsh right
#
# Layout:
#
#   left:
#       1/3 | 2/3
#
#   even / balance:
#       1/2 | 1/2
#
#   right:
#       2/3 | 1/3
#
# This intentionally adjusts one usable BSP split rather than running
# `yabai -m space --balance`, which recursively balances the entire
# BSP tree.

emulate -LR zsh
setopt nounset pipefail

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

[[ -x $YABAI ]] || {
  print -ru2 -- "space-thirds: yabai not found: $YABAI"
  exit 69
}

[[ -x $JQ ]] || {
  print -ru2 -- "space-thirds: jq not found: $JQ"
  exit 69
}

typeset mode=${1:-}
typeset ratio

case $mode in
  left)
    ratio=0.3333
    ;;

  even|balance)
    ratio=0.5000
    ;;

  right)
    ratio=0.6667
    ;;

  *)
    print -ru2 -- "usage: ${0:t} left|even|right"
    exit 64
    ;;
esac


# ----------------------------------------------------------------------
# Verify current Space is BSP
# ----------------------------------------------------------------------

typeset layout

layout=$(
  "$YABAI" -m query --spaces type --space 2>/dev/null |
    "$JQ" -r '.type // empty'
) || exit 1

[[ $layout == bsp ]] || {
  print -ru2 -- "space-thirds: current Space is not BSP"
  exit 1
}


# ----------------------------------------------------------------------
# Preserve focused window
# ----------------------------------------------------------------------

typeset original_id

original_id=$(
  "$YABAI" -m query --windows id --window 2>/dev/null |
    "$JQ" -r '.id // empty'
)


# ----------------------------------------------------------------------
# Find usable tiled windows
#
# We intentionally exclude floating, minimized, hidden and native
# fullscreen windows.
#
# Sorting left-to-right/top-to-bottom makes the operation predictable
# and preserves the behaviour that has already proved useful on the
# Reading Space.
# ----------------------------------------------------------------------

typeset -a candidates

candidates=("${(@f)$(
  "$YABAI" -m query --windows --space 2>/dev/null |
    "$JQ" -r '
      map(
        select(
          .["is-visible"] == true and
          .["is-minimized"] == false and
          .["is-hidden"] == false and
          .["is-floating"] == false and
          .["is-native-fullscreen"] == false and
          .["split-type"] != "none"
        )
      )
      | sort_by(.frame.x, .frame.y, .id)
      | .[].id
    '
)}")


# A ratio requires at least two managed windows.
(( ${#candidates} >= 2 )) || {
  print -ru2 -- "space-thirds: fewer than two tiled windows"
  exit 1
}


# ----------------------------------------------------------------------
# Apply ratio
#
# A BSP window's ratio controls its associated parent split. Not every
# window is necessarily attached to an adjustable split, so try the
# candidates in stable physical order until yabai accepts the ratio.
# ----------------------------------------------------------------------

typeset -i adjusted=0
typeset window_id

for window_id in $candidates; do
  if "$YABAI" -m window "$window_id" \
       --ratio "abs:$ratio" 2>/dev/null; then

    adjusted=1
    break
  fi
done


# ----------------------------------------------------------------------
# Restore original focus
# ----------------------------------------------------------------------

if [[ -n $original_id ]]; then
  "$YABAI" -m window --focus "$original_id" >/dev/null 2>&1
fi


(( adjusted )) || {
  print -ru2 -- "space-thirds: could not adjust a BSP split"
  exit 1
}

exit 0
