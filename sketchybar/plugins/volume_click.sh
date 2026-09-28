#!/usr/bin/env bash

# Load global styles, colors and icons
source "$CONFIG_DIR/globalstyles.sh"

WIDTH=100

detail_on() {
  sketchybar --animate tanh 30 --set volume slider.width=$WIDTH
}

detail_off() {
  sketchybar --animate tanh 30 --set volume slider.width=0
}

toggle_detail() {
  INITIAL_WIDTH=$(sketchybar --query volume | jq -r ".slider.width")
  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    detail_on
  else
    detail_off
  fi
}

toggle_devices() {
  local switch_audio=/usr/local/bin/SwitchAudioSource
  if [[ ! -x "$switch_audio" ]]; then
    source "$CONFIG_DIR/log.sh"
    sketchybar_log warn "SwitchAudioSource is unavailable; device popup disabled"
    return 0
  fi
  source "$CONFIG_DIR/colors.sh"
  source "$CONFIG_DIR/globalstyles.sh"

  args=(--remove '/volume.device\..*/' --set $NAME popup.drawing=toggle "${menu_defaults[@]}")

  COUNTER=0
  CURRENT="$("$switch_audio" -t output -c)"

  while IFS= read -r device; do
    printf -v quoted_device '%q' "$device"
    COLOR=$LABEL_COLOR
    ICON=􀆅
    ICON_COLOR=$TRANSPARENT

    if [ "${device}" == "$CURRENT" ]; then
      COLOR=$HIGHLIGHT
      ICON_COLOR=$HIGHLIGHT
    fi

    args+=(--add item volume.device.$COUNTER popup.$NAME           \
           --set volume.device.$COUNTER label="${device}"          \
                                        "${menu_item_defaults[@]}" \
                                        label.color="$COLOR"       \
                                        icon=$ICON                 \
                                        icon.color=$ICON_COLOR     \
    click_script="$switch_audio -s $quoted_device && sketchybar --set /volume.device\..*/ label.color=$COLOR --set \$NAME label.color=$COLOR --set $NAME popup.drawing=off")

    COUNTER=$((COUNTER+1))
  done <<< "$("$switch_audio" -a -t output)"

  sketchybar -m "${args[@]}" > /dev/null
}

if [ "$BUTTON" = "left" ] || [ "$MODIFIER" = "shift" ]; then
  toggle_devices
else
  toggle_detail
fi
