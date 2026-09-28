#!/usr/bin/env bash

# SketchyBar Wi-Fi menu script
# Handles macOS redacted SSID values from `ipconfig getsummary`.

# Loads defined colors
source "$CONFIG_DIR/colors.sh"

# --------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------

get_wifi_iface() {
  /usr/sbin/networksetup -listallhardwareports | /usr/bin/awk '
    /Hardware Port: (Wi-Fi|AirPort)/ {
      getline
      print $2
      exit
    }
  '
}

get_ssid_from_ipconfig_summary() {
  local summary="$1"

  printf '%s\n' "$summary" | /usr/bin/awk -F ' : ' '
    $1 ~ /^[[:space:]]*SSID[[:space:]]*$/ {
      print $2
      exit
    }
  '
}

get_ssid_from_system_profiler() {
  # Slower, but useful as a fallback when ipconfig redacts SSID.
  /usr/sbin/system_profiler SPAirPortDataType 2>/dev/null | /usr/bin/awk -F ': ' '
    /Current Network Information:/ {
      getline
      gsub(/^[[:space:]]+/, "", $1)
      print $1
      exit
    }
  '
}

clean_redacted_value() {
  local value="$1"

  case "$value" in
    ""|"<redacted>"|"redacted")
      printf ''
      ;;
    *)
      printf '%s' "$value"
      ;;
  esac
}

# --------------------------------------------------------------------
# State detection
# --------------------------------------------------------------------

WIFI_IFACE="$(get_wifi_iface)"

IS_VPN="$(/usr/local/bin/piactl get connectionstate 2>/dev/null || echo "Disconnected")"

CURRENT_WIFI=""
IP_ADDRESS=""
SSID=""

if [[ -n "$WIFI_IFACE" ]]; then
  CURRENT_WIFI="$(/usr/sbin/ipconfig getsummary "$WIFI_IFACE" 2>/dev/null || true)"
  IP_ADDRESS="$(/usr/sbin/ipconfig getifaddr "$WIFI_IFACE" 2>/dev/null || true)"

  SSID="$(get_ssid_from_ipconfig_summary "$CURRENT_WIFI")"
  SSID="$(clean_redacted_value "$SSID")"

  # Fallback only if ipconfig did not provide a usable SSID.
  if [[ -z "$SSID" && -n "$IP_ADDRESS" ]]; then
    SSID="$(get_ssid_from_system_profiler)"
    SSID="$(clean_redacted_value "$SSID")"
  fi
fi

# --------------------------------------------------------------------
# Icon logic
# --------------------------------------------------------------------

ICON_COLOR="$(getcolor white 25)"
ICON=􀐾

if [[ "$IS_VPN" != "Disconnected" ]]; then
  ICON_COLOR=$HIGHLIGHT
  ICON=􀎡
elif [[ "$SSID" == "nairvana" ]]; then
  ICON_COLOR="$(getcolor white)"
  ICON=􀉤
elif [[ -n "$SSID" ]]; then
  ICON_COLOR="$(getcolor white)"
  ICON=􀐿
elif [[ -n "$IP_ADDRESS" ]]; then
  # Wi-Fi is connected, but SSID is unavailable/redacted.
  ICON_COLOR="$(getcolor white)"
  ICON=􀐿
else
  ICON_COLOR="$(getcolor white 25)"
  ICON=􀐾
fi

# --------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------

render_bar_item() {
  local DRAWING="on"

  if [[ -f "${TMPDIR:-/tmp}/sketchybar-${UID}-sender" ]] && [[ "$(/bin/cat "${TMPDIR:-/tmp}/sketchybar-${UID}-sender")" == "focus_on" ]]; then
    DRAWING="off"
  fi

  sketchybar --set "$NAME" \
    icon.color="$ICON_COLOR" \
    icon="$ICON" \
    drawing="$DRAWING"
}

render_popup() {
  local ssid_label
  local ip_label

  if [[ -n "$SSID" ]]; then
    ssid_label="$SSID"
  elif [[ -n "$IP_ADDRESS" ]]; then
    ssid_label="Wi-Fi connected; SSID hidden"
  else
    ssid_label="Not connected"
  fi

  ip_label="${IP_ADDRESS:-No IP}"

  sketchybar \
    --set wifi.ssid \
      label="$ssid_label" \
    --set wifi.ipaddress \
      label="$ip_label" \
      click_script="printf '%s' '$ip_label' | pbcopy; sketchybar --set wifi popup.drawing=toggle" \
    >/dev/null
}

update() {
  render_bar_item
  render_popup
}

popup() {
  sketchybar --set "$NAME" popup.drawing="$1"
}

# --------------------------------------------------------------------
# Event handling
# --------------------------------------------------------------------

case "$SENDER" in
  "routine" | "forced")
    update
    ;;
  "mouse.clicked")
    popup toggle
    ;;
esac
