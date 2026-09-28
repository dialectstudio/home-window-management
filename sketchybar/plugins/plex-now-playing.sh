#!/usr/bin/env bash

set -u

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
config_file="${PLEX_CONF:-$CONFIG_DIR/config/plex.conf}"

[[ -r "$config_file" ]] || {
  printf '%s\n' "Nothing is playing."
  exit 0
}

# shellcheck source=/dev/null
source "$config_file"

[[ -n "${PLEX_URL:-}" && -r "${PLEX_TOKEN_FILE:-}" ]] || {
  printf '%s\n' "Nothing is playing."
  exit 0
}

plex_token=$(<"$PLEX_TOKEN_FILE")
plex_base="http://$PLEX_URL:32400"

plex_curl() {
  local url="$1"
  shift
  printf 'header = "X-Plex-Token: %s"\n' "$plex_token" |
    /usr/bin/curl --config - -sS --max-time 3 "$url" "$@"
}

# Fetch the XML response
if ! response=$(plex_curl "$plex_base/status/sessions"); then
    echo "Error: Failed to fetch data from Plex server."
    exit 1
fi

# Check if any media is currently playing
if echo "$response" | grep -q 'MediaContainer size="0"'; then
    echo "Nothing is playing."
    exit 0
fi


# Parse and display Artist, Song Name, and Album Name
artist=$(echo "$response" | xmllint --xpath 'string(//Track/@grandparentTitle)' -)
song=$(echo "$response" | xmllint --xpath 'string(//Track/@title)' -)
album=$(echo "$response" | xmllint --xpath 'string(//Track/@parentTitle)' -)
artwork=$(echo "$response" | xmllint --xpath 'string(//Track/@parentThumb)' -)
state=$(echo "$response" | xmllint --xpath 'string(//Track/Player/@state)' -)

# Download the artwork image and save it in a temporary folder
artwork_path="${TMPDIR:-/tmp}/sketchybar-plex-artwork.jpg"
plex_curl "$plex_base$artwork" -o "$artwork_path" || artwork_path=""

# Output the information clearly
echo "$state|$artist|$song|$artwork_path"
