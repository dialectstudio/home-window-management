#!/usr/bin/env bash

: "${SKETCHYBAR_LOG_LEVEL_FILE:=${TMPDIR:-/tmp}/sketchybar-${UID}.log-level}"
if [[ -z "${SKETCHYBAR_LOG_LEVEL:-}" && -r "$SKETCHYBAR_LOG_LEVEL_FILE" ]]; then
  IFS= read -r SKETCHYBAR_LOG_LEVEL <"$SKETCHYBAR_LOG_LEVEL_FILE"
fi
: "${SKETCHYBAR_LOG_LEVEL:=warn}"
: "${SKETCHYBAR_LOG_FILE:=${TMPDIR:-/tmp}/sketchybar-${UID}.log}"

sketchybar_log() {
  local level="$1"
  shift

  local configured=2 requested=2
  case "$SKETCHYBAR_LOG_LEVEL" in
    debug) configured=0 ;;
    info) configured=1 ;;
    warn) configured=2 ;;
    error) configured=3 ;;
    off) configured=4 ;;
  esac
  case "$level" in
    debug) requested=0 ;;
    info) requested=1 ;;
    warn) requested=2 ;;
    error) requested=3 ;;
  esac

  (( requested < configured )) && return 0
  printf '%s [%s] %s\n' "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z')" "$level" "$*" \
    >>"$SKETCHYBAR_LOG_FILE"
}
