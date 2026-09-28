#!/usr/bin/env bash

# SketchyBar weather plugin using WeatherAPI.com current weather.
#
# Secret file supported formats:
#   raw key
#   API_KEY=...
#   WEATHER_API_KEY=...
#   WEATHER_KEY=...
#   WEATHERAPI_KEY=...
#   WEATHERAPI_API_KEY=...
#   WEATHERAPI_COM_API_KEY=...
#
# Each KEY=VALUE form may optionally be prefixed with "export".

set -u

item_name="${NAME:-weather}"
config_dir="${CONFIG_DIR:-$HOME/.config/sketchybar}"
secret_dir="${SKETCHYBAR_SECRET_DIR:-$HOME/.dotfiles/secrets}"
secret_file="${WEATHER_SECRET_FILE:-$secret_dir/weather}"
weather_conf="${WEATHER_CONF:-$config_dir/config/weather.conf}"
cache_file="${TMPDIR:-/tmp}/sketchybar-weatherapi.json"
state_file="${TMPDIR:-/tmp}/sketchybar-weather.state"
debug_log="${TMPDIR:-/tmp}/sketchybar-weather.debug.log"

WEATHER_QUERY="auto:ip"
WEATHER_UNITS="metric"       # metric or imperial
WEATHER_AQI="no"             # WeatherAPI.com accepts yes/no
WEATHER_LANG=""              # optional, e.g. en, fr, de
WEATHER_LABEL_MODE="temp"    # temp, temp_condition, condition
declare -A WEATHER_QUERY_BY_LOCATION=()

# This file is local config, not a secret; it is intentionally sourced.
# shellcheck source=/dev/null
[[ -r "$weather_conf" ]] && source "$weather_conf"

set_item() {
  local icon="$1" label="$2"
  if command -v sketchybar >/dev/null 2>&1; then
    sketchybar --set "$item_name" icon="$icon" label="$label"
  else
    printf '%s %s\n' "$icon" "$label"
  fi
}

write_state() {
  # State file deliberately excludes the API key.
  {
    printf 'time=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
    printf 'provider=%s\n' "WeatherAPI.com"
    printf 'location=%s\n' "${network_location:-unknown}"
    printf 'query=%s\n' "${query:-unset}"
    printf 'units=%s\n' "${WEATHER_UNITS:-unset}"
    printf 'aqi=%s\n' "${WEATHER_AQI:-unset}"
    printf 'status=%s\n' "${http_status:-unset}"
    printf 'api_code=%s\n' "${api_code:-none}"
    printf 'error=%s\n' "${error_label:-none}"
    printf 'message=%s\n' "${api_message:-none}"
    printf 'condition=%s\n' "${condition_text:-none}"
    printf 'last_updated=%s\n' "${last_updated:-none}"
  } > "$state_file"
}

trim_string() {
  local s="$1"
  # shellcheck disable=SC2001
  s="$(printf '%s' "$s" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  printf '%s\n' "$s"
}

strip_wrapping_quotes() {
  local s="$1"
  if [[ ${#s} -ge 2 ]]; then
    if [[ "${s:0:1}" == '"' && "${s: -1}" == '"' ]]; then
      s="${s:1:${#s}-2}"
    elif [[ "${s:0:1}" == "'" && "${s: -1}" == "'" ]]; then
      s="${s:1:${#s}-2}"
    fi
  fi
  printf '%s\n' "$s"
}

read_api_key() {
  local file="$1"
  local line key value
  [[ -r "$file" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(trim_string "$line")"
    [[ -z "$line" ]] && continue

    # Allow: export WEATHER_API_KEY=abc123
    line="$(printf '%s' "$line" | sed -E 's/^export[[:space:]]+//')"

    if [[ "$line" == *=* ]]; then
      key="${line%%=*}"
      value="${line#*=}"
      key="$(trim_string "$key")"
      value="$(trim_string "$value")"
      value="$(strip_wrapping_quotes "$value")"

      case "$key" in
        API_KEY|WEATHER_API_KEY|WEATHER_KEY|WEATHERAPI_KEY|WEATHERAPI_API_KEY|WEATHERAPI_COM_API_KEY)
          printf '%s\n' "$value"
          return 0
          ;;
      esac
    else
      value="$(strip_wrapping_quotes "$line")"
      printf '%s\n' "$value"
      return 0
    fi
  done < "$file"

  return 1
}

weather_icon() {
  local code="$1" is_day="$2"

  case "$code" in
    1000)
      if [[ "$is_day" == "1" ]]; then printf '☀'; else printf '☾'; fi
      ;;
    1003) printf '⛅' ;;
    1006|1009) printf '☁' ;;
    1030|1135|1147) printf '≋' ;;
    1063|1072|1150|1153|1168|1171|1180|1183|1186|1189|1192|1195|1198|1201|1240|1243|1246) printf '☔' ;;
    1066|1114|1117|1210|1213|1216|1219|1222|1225|1255|1258) printf '❄' ;;
    1069|1204|1207|1237|1249|1252|1261|1264) printf '🌨' ;;
    1087|1273|1276|1279|1282) printf '⛈' ;;
    *) printf '☁' ;;
  esac
}

api_key="$(read_api_key "$secret_file" 2>/dev/null || true)"

if [[ -z "$api_key" ]]; then
  error_label="key"
  api_message="missing WeatherAPI.com API key"
  api_code="none"
  http_status="unset"
  network_location="$(/usr/sbin/networksetup -getcurrentlocation 2>/dev/null | tr -d '\r')"
  query="unset"
  condition_text="none"
  last_updated="none"
  write_state
  set_item "☁" "key"
  exit 0
fi

network_location="$(/usr/sbin/networksetup -getcurrentlocation 2>/dev/null | tr -d '\r')"
query="${WEATHER_QUERY_BY_LOCATION[$network_location]:-$WEATHER_QUERY}"

if ! command -v jq >/dev/null 2>&1; then
  error_label="jq"
  api_message="jq is not installed or not on PATH"
  api_code="none"
  http_status="unset"
  condition_text="none"
  last_updated="none"
  write_state
  set_item "☁" "jq"
  exit 0
fi

body_file="$(mktemp "${TMPDIR:-/tmp}/sketchybar-weatherapi-body.XXXXXX")"
trap 'rm -f "$body_file"' EXIT

curl_args=(
  -sS
  --connect-timeout 4
  --max-time 10
  --get
  --output "$body_file"
  --write-out '%{http_code}'
  'https://api.weatherapi.com/v1/current.json'
  --data-urlencode "q=$query"
  --data-urlencode "aqi=${WEATHER_AQI:-no}"
)

if [[ -n "${WEATHER_LANG:-}" ]]; then
  curl_args+=(--data-urlencode "lang=$WEATHER_LANG")
fi

# Capture curl's status without letting curl output contaminate http_status.
if ! http_status="$(
  printf 'data-urlencode = "key=%s"\n' "$api_key" |
    /usr/bin/curl --config - "${curl_args[@]}" 2>"$debug_log"
)"; then
  http_status="000"
fi

json="$(cat "$body_file" 2>/dev/null || true)"
api_code="$(jq -r '.error.code // empty | tostring' <<<"$json" 2>/dev/null || true)"
api_message="$(jq -r '.error.message // empty' <<<"$json" 2>/dev/null || true)"
condition_text="$(jq -r '.current.condition.text // empty' <<<"$json" 2>/dev/null || true)"
last_updated="$(jq -r '.current.last_updated // empty' <<<"$json" 2>/dev/null || true)"

if [[ "$http_status" == "200" && -n "$json" && -n "$condition_text" ]]; then
  printf '%s\n' "$json" > "$cache_file"
elif [[ -r "$cache_file" && -s "$cache_file" ]]; then
  # Keep the bar useful if the network/API has a temporary problem after a good fetch.
  json="$(cat "$cache_file")"
  api_code="cached"
  [[ -z "$api_message" ]] && api_message="using cached WeatherAPI.com response after HTTP $http_status"
  condition_text="$(jq -r '.current.condition.text // empty' <<<"$json" 2>/dev/null || true)"
  last_updated="$(jq -r '.current.last_updated // empty' <<<"$json" 2>/dev/null || true)"
else
  case "$http_status:$api_code" in
    000:*) error_label="net"; [[ -z "$api_message" ]] && api_message="network, DNS, TLS, or timeout failure" ;;
    401:1002) error_label="key" ;;
    401:2006) error_label="auth" ;;
    403:2007) error_label="lim" ;;
    403:2008) error_label="disabled" ;;
    403:2009) error_label="plan" ;;
    400:1003) error_label="query" ;;
    400:1005) error_label="url" ;;
    400:1006) error_label="loc" ;;
    400:9999|*:9999) error_label="api" ;;
    *) error_label="api"; [[ -z "$api_message" ]] && api_message="WeatherAPI.com HTTP $http_status" ;;
  esac
  condition_text="none"
  last_updated="none"
  write_state
  set_item "☁" "$error_label"
  exit 0
fi

code="$(jq -r '.current.condition.code // empty | tostring' <<<"$json" 2>/dev/null || true)"
is_day="$(jq -r '.current.is_day // empty | tostring' <<<"$json" 2>/dev/null || true)"

if [[ "$WEATHER_UNITS" == "imperial" ]]; then
  temp="$(jq -r '.current.temp_f // empty | round' <<<"$json" 2>/dev/null || true)"
  suffix="°F"
else
  temp="$(jq -r '.current.temp_c // empty | round' <<<"$json" 2>/dev/null || true)"
  suffix="°C"
fi

if [[ -z "$temp" || -z "$code" ]]; then
  error_label="parse"
  [[ -z "$api_message" ]] && api_message="WeatherAPI.com response was missing expected current fields"
  write_state
  set_item "☁" "parse"
  exit 0
fi

icon="$(weather_icon "$code" "$is_day")"

case "${WEATHER_LABEL_MODE:-temp}" in
  temp_condition)
    label="${temp}${suffix} ${condition_text}"
    ;;
  condition)
    label="${condition_text}"
    ;;
  *)
    label="${temp}${suffix}"
    ;;
esac

error_label="none"
api_message="ok"
write_state
set_item "$icon" "$label"
