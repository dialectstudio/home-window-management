#!/bin/zsh

emulate -LR zsh
setopt nounset pipefail

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

[[ -x $YABAI && -x $JQ ]] || exit 69

layout=$(
  "$YABAI" -m query --spaces --space 2>/dev/null |
    "$JQ" -r '.type // .layout // empty'
) || exit 1

case $layout in
  float)
    "$YABAI" -m space --layout bsp &&
      "$YABAI" -m space --balance
    ;;
  bsp|stack)
    "$YABAI" -m space --layout float
    ;;
  *)
    print -ru2 -- "toggle-space-layout: unknown current layout: ${layout:-empty}"
    exit 1
    ;;
esac
