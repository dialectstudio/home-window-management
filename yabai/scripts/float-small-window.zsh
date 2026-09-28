#!/bin/zsh

# ~/.config/yabai/scripts/float-small-window.zsh
#
# Intended for yabai's window_created signal.
#
# Automatically float a newly created window when:
#   - it cannot be resized; or
#   - its area is less than 10% of its display area.
#
# yabai supplies YABAI_WINDOW_ID for window_created signals.
# A window ID may also be supplied explicitly for testing:
#
#   float-small-window.zsh 12345

emulate -LR zsh
setopt nounset pipefail

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq
typeset -gr -F SMALL_WINDOW_RATIO=0.10

[[ -x $YABAI ]] || {
  print -ru2 -- "float-small-window: yabai not found: $YABAI"
  exit 69
}

[[ -x $JQ ]] || {
  print -ru2 -- "float-small-window: jq not found: $JQ"
  exit 69
}

typeset window_id=${1:-${YABAI_WINDOW_ID:-}}

[[ -n $window_id ]] || {
  print -ru2 -- "float-small-window: no window id supplied"
  exit 64
}

typeset window_json values
typeset display_id window_w window_h
typeset can_resize is_floating has_ax_reference

# A newly created window may briefly exist before yabai has obtained
# its Accessibility reference. Retry briefly rather than acting on
# potentially incomplete can-resize information.
typeset -i attempt

for attempt in {1..5}; do
  window_json=$(
    "$YABAI" -m query --windows \
      id,display,frame,can-resize,is-floating,has-ax-reference \
      --window "$window_id" 2>/dev/null
  ) || {
    /bin/sleep 0.05
    continue
  }

  values=$(
    print -r -- "$window_json" |
      "$JQ" -r '
        [
          .display,
          .frame.w,
          .frame.h,
          .["can-resize"],
          .["is-floating"],
          .["has-ax-reference"]
        ]
        | @tsv
      '
  )

  IFS=$'\t' read -r \
    display_id \
    window_w \
    window_h \
    can_resize \
    is_floating \
    has_ax_reference <<< "$values"

  [[ $has_ax_reference == true ]] && break

  /bin/sleep 0.05
done

# Do nothing if yabai still has no usable AX reference.
[[ ${has_ax_reference:-false} == true ]] || exit 0

# Already floating: nothing to do.
[[ $is_floating == false ]] || exit 0

# Non-resizable windows should not enter the BSP tree.
if [[ $can_resize == false ]]; then
  exec "$YABAI" -m window "$window_id" --toggle float
fi

typeset display_json display_values
typeset display_w display_h

display_json=$(
  "$YABAI" -m query --displays frame \
    --display "$display_id" 2>/dev/null
) || exit 0

display_values=$(
  print -r -- "$display_json" |
    "$JQ" -r '[.frame.w, .frame.h] | @tsv'
)

IFS=$'\t' read -r display_w display_h <<< "$display_values"

# zsh arithmetic supports floating point directly; no bc subprocess
# is required.
if (( window_w * window_h <
      display_w * display_h * SMALL_WINDOW_RATIO )); then

  exec "$YABAI" -m window "$window_id" --toggle float
fi

exit 0
