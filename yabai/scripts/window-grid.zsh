#!/bin/zsh

# ~/.config/yabai/scripts/window-grid.zsh
#
# Position the focused floating window using a named yabai grid.
#
# Usage:
#   window-grid.zsh center
#   window-grid.zsh lefthalf
#   window-grid.zsh righthalf
#   window-grid.zsh tophalf
#   window-grid.zsh bottomhalf
#   window-grid.zsh topleft
#   window-grid.zsh bottomleft
#   window-grid.zsh topright
#   window-grid.zsh bottomright

emulate -LR zsh
setopt nounset pipefail

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

[[ -x $YABAI ]] || {
  print -ru2 -- "window-grid: yabai not found: $YABAI"
  exit 69
}

[[ -x $JQ ]] || {
  print -ru2 -- "window-grid: jq not found: $JQ"
  exit 69
}

typeset -r position=${1:-}

typeset -A grids=(
  center       '5:5:1:1:3:3'

  lefthalf     '1:2:0:0:1:1'
  righthalf    '1:2:1:0:1:1'

  tophalf      '2:1:0:0:1:1'
  bottomhalf   '2:1:0:1:1:1'

  topleft      '2:2:0:0:1:1'
  bottomleft   '2:2:0:1:1:1'
  topright     '2:2:1:0:1:1'
  bottomright  '2:2:1:1:1:1'
)

typeset destination=${grids[$position]:-}

[[ -n $destination ]] || {
  print -ru2 -- "usage: ${0:t} POSITION"
  print -ru2 -- \
    "positions: center lefthalf righthalf tophalf bottomhalf topleft bottomleft topright bottomright"
  exit 64
}

typeset is_floating

is_floating=$(
  "$YABAI" -m query --windows is-floating --window 2>/dev/null |
    "$JQ" -r '.["is-floating"]'
) || {
  print -ru2 -- "window-grid: no focused yabai window"
  exit 1
}

[[ $is_floating == true ]] || {
  print -ru2 -- \
    "window-grid: focused window is managed; toggle float first"
  exit 1
}

exec "$YABAI" -m window --grid "$destination"
