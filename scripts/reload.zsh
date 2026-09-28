#!/bin/zsh

source "${0:A:h}/lib.zsh"
setopt errexit

typeset -a apps
if (( $# )); then
  apps=("$@")
else
  apps=(yabai skhd sketchybar borders)
fi

for app in "${apps[@]}"; do
  [[ $app == (yabai|skhd|sketchybar|borders) ]] || die "unknown app: $app"
done

"$SCRIPT_DIR/check.zsh" >/dev/null ||
  die "checks failed; refusing to reload"

"$SCRIPT_DIR/status.zsh" >/dev/null ||
  die "managed links are incomplete; run make status before reloading"

for app in yabai skhd sketchybar borders; do
  (( ${apps[(Ie)$app]} )) || continue

  case $app in
    yabai) /usr/local/bin/yabai --restart-service ;;
    skhd)
      typeset restart_keyclu=false
      if [[ -d /Applications/KeyClu.app ]] && /usr/bin/pgrep -x KeyClu >/dev/null 2>&1; then
        restart_keyclu=true
        /usr/bin/pkill -x KeyClu
        while /usr/bin/pgrep -x KeyClu >/dev/null 2>&1; do
          /bin/sleep 0.05
        done
      fi

      if /usr/bin/pgrep -x skhd >/dev/null 2>&1; then
        /usr/local/bin/skhd --reload
      else
        /usr/local/bin/skhd --start-service
      fi

      if $restart_keyclu; then
        /usr/bin/open -g /Applications/KeyClu.app
      fi
      ;;
    sketchybar) /usr/local/bin/sketchybar --reload ;;
    borders) /usr/local/bin/brew services restart borders ;;
  esac
done
