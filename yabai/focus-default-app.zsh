#!/bin/zsh

# ~/.config/yabai/focus-default-app.zsh
#
# Focus the designated application when entering spaces 1–6.
# Spaces 7–9 intentionally have no default application.
#
# The script only focuses windows already located on the active space.
# It never follows an application's window to another space.

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq
typeset -gr CONFIG_DIR=${0:A:h}
typeset -gr WORKSPACES_FILE="$CONFIG_DIR/workspaces.tsv"

[[ -x $YABAI ]] || exit 1
[[ -x $JQ ]] || exit 1
[[ -r $WORKSPACES_FILE ]] || exit 1

# yabai supplies YABAI_SPACE_INDEX for a space_changed signal.
# Query the current space as a fallback so this script can also be
# executed manually for testing.
space=${YABAI_SPACE_INDEX:-}

if [[ -z $space ]]; then
  space=$(
    "$YABAI" -m query --spaces --space 2>/dev/null |
      "$JQ" -r '.index'
  )
fi

[[ $space == <-> ]] || exit 0

app_regex=""
space_label=$(
  "$YABAI" -m query --spaces --space "$space" 2>/dev/null |
    "$JQ" -r '.label // empty'
)

while IFS=$'\t' read -r index label layout default_app placement; do
  if [[ -n $space_label && $label == $space_label ]]; then
    [[ $default_app != - ]] && app_regex=$default_app
    break
  fi
done < "$WORKSPACES_FILE"

# Spaces 7–9 (and anything else) deliberately have no default app.
[[ -n $app_regex ]] || exit 0

# Allow the macOS space transition to settle before selecting a window.
# Keep this short so keyboard-driven space changes still feel immediate.
/bin/sleep 0.05

window_id=$(
  "$YABAI" -m query --windows --space "$space" 2>/dev/null |
    "$JQ" -r --arg app "$app_regex" '
      [
        .[]
        | select(.app | test($app))
        | select(."is-minimized" == false)
      ]
      | .[0].id // empty
    '
)

if [[ -n $window_id ]]; then
  "$YABAI" -m window "$window_id" --focus >/dev/null 2>&1
  exit $?
fi

# Finder is always running but Home may have no Finder window.
# In that one case, make Finder the active application without creating
# a window or looking for one on another space.
if [[ $space_label == Home ]]; then
  /usr/bin/osascript \
    -e 'tell application "Finder" to activate' \
    >/dev/null 2>&1
fi

exit 0
