#!/bin/zsh

# ~/.config/yabai/topology.zsh
#
# Reconcile yabai display/Space topology.
#
# Goals:
#   - maintain nine semantic workspaces
#   - use stable Space labels instead of Mission Control indices
#   - identify physical displays by UUID
#   - restore desired Space placement when displays reconnect
#   - preserve existing labeled Spaces whenever possible
#   - reuse existing unlabeled Spaces before creating new ones
#   - NEVER destroy Spaces automatically
#
# Usage:
#   topology.zsh
#   topology.zsh apply
#   topology.zsh status
#   topology.zsh displays
#
# Optional machine-specific configuration:
#
#   ~/.config/yabai/topology.local.zsh
#
# This file intentionally uses zsh syntax and must remain executable.

emulate -LR zsh
setopt nounset pipefail

# ----------------------------------------------------------------------
# Paths
# ----------------------------------------------------------------------

typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

typeset -gr CONFIG_DIR=${0:A:h}
typeset -gr LOCAL_CONFIG="${CONFIG_DIR}/topology.local.zsh"
typeset -gr WORKSPACES_FILE="${CONFIG_DIR}/workspaces.tsv"

typeset -gr LOCK_DIR="/tmp/yabai-topology-${UID}.lock"


# ----------------------------------------------------------------------
# Semantic workspace model
#
# Order in workspaces.tsv is significant when initially assigning labels to
# existing unlabeled Spaces.
# ----------------------------------------------------------------------

[[ -r $WORKSPACES_FILE ]] || {
  print -ru2 -- "[topology] error: workspace model not found: $WORKSPACES_FILE"
  exit 1
}

typeset -ga SPACE_NAMES=()
typeset -gA SPACE_LAYOUTS=()
typeset workspace_index workspace_name workspace_layout workspace_default workspace_apps

while IFS=$'\t' read -r workspace_index workspace_name workspace_layout workspace_default workspace_apps; do
  [[ $workspace_index == <-> && -n $workspace_name && -n $workspace_layout ]] || {
    print -ru2 -- "[topology] error: invalid workspace record: $workspace_index $workspace_name"
    exit 1
  }

  SPACE_NAMES[$workspace_index]=$workspace_name
  SPACE_LAYOUTS[$workspace_name]=$workspace_layout
done < "$WORKSPACES_FILE"


# ----------------------------------------------------------------------
# Display topology
#
# DISPLAY_UUIDS maps a human-readable display role to a physical
# display UUID:
#
#   DISPLAY_UUIDS[primary]="..."
#   DISPLAY_UUIDS[secondary]="..."
#
# SPACE_TARGETS maps a semantic Space to one of those display roles:
#
#   SPACE_TARGETS[Research]=secondary
#
# These are deliberately empty here. Machine-specific values belong
# in topology.local.zsh.
# ----------------------------------------------------------------------

typeset -gA DISPLAY_UUIDS=()
typeset -gA SPACE_TARGETS=()


# Reuse existing unlabeled Spaces before creating new ones.
typeset -gi REUSE_UNLABELED_SPACES=1


# ----------------------------------------------------------------------
# Local machine-specific overrides
# ----------------------------------------------------------------------

if [[ -r $LOCAL_CONFIG ]]; then
  source "$LOCAL_CONFIG"
fi


# ----------------------------------------------------------------------
# Basic helpers
# ----------------------------------------------------------------------

log() {
  [[ ${TOPOLOGY_QUIET:-0} == 1 ]] && return 0
  print -r -- "[topology] $*"
}

warn() {
  print -ru2 -- "[topology] warning: $*"
}

die() {
  print -ru2 -- "[topology] error: $*"
  exit 1
}


[[ -x $YABAI ]] ||
  die "yabai not found: $YABAI"

[[ -x $JQ ]] ||
  die "jq not found: $JQ"


# ----------------------------------------------------------------------
# Display lookup helpers
# ----------------------------------------------------------------------

display_index_for_uuid() {
  local uuid=$1

  "$YABAI" -m query --displays uuid,index 2>/dev/null |
    "$JQ" -er \
      --arg uuid "$uuid" \
      'first(.[] | select(.uuid == $uuid) | .index) // empty'
}


display_exists() {
  local selector=$1

  "$YABAI" -m query --displays index \
    --display "$selector" >/dev/null 2>&1
}


display_index() {
  local selector=$1

  "$YABAI" -m query --displays index \
    --display "$selector" 2>/dev/null |
    "$JQ" -er '.index'
}


display_label_for_index() {
  local index=$1

  "$YABAI" -m query --displays label \
    --display "$index" 2>/dev/null |
    "$JQ" -r '.label // ""'
}


# ----------------------------------------------------------------------
# Space lookup helpers
# ----------------------------------------------------------------------

space_index_by_label() {
  local label=$1

  "$YABAI" -m query --spaces label,index 2>/dev/null |
    "$JQ" -er \
      --arg label "$label" \
      'first(.[] | select(.label == $label) | .index) // empty'
}


space_display_index() {
  local selector=$1

  "$YABAI" -m query --spaces display \
    --space "$selector" 2>/dev/null |
    "$JQ" -er '.display'
}


unlabeled_space_on_display() {
  local display=$1

  "$YABAI" -m query --spaces \
    label,index,is-native-fullscreen \
    --display "$display" 2>/dev/null |
    "$JQ" -er '
      first(
        .[]
        | select(
            (.label // "") == "" and
            .["is-native-fullscreen"] == false
          )
        | .index
      ) // empty
    '
}


first_unlabeled_space() {
  "$YABAI" -m query --spaces \
    label,index,is-native-fullscreen 2>/dev/null |
    "$JQ" -er '
      first(
        .[]
        | select(
            (.label // "") == "" and
            .["is-native-fullscreen"] == false
          )
        | .index
      ) // empty
    '
}


# ----------------------------------------------------------------------
# Stable display labels
#
# yabai's display selector accepts display labels, but not UUIDs.
#
# We therefore:
#
#   physical UUID -> arrangement index -> yabai display label
#
# and subsequently use only the human-readable display label.
# ----------------------------------------------------------------------

reconcile_display_labels() {
  local role uuid index current_label

  (( ${#DISPLAY_UUIDS} )) || {
    log "No display UUID mapping configured"
    return 0
  }

  for role in ${(k)DISPLAY_UUIDS}; do
    uuid=${DISPLAY_UUIDS[$role]}

    [[ -n $uuid ]] || continue

    index=$(display_index_for_uuid "$uuid" 2>/dev/null) || {
      log "Display '$role' is not currently connected"
      continue
    }

    current_label=$(display_label_for_index "$index")

    if [[ $current_label == $role ]]; then
      log "Display $index already labelled '$role'"
      continue
    fi

    if [[ -n $current_label ]]; then
      log "Relabelling display $index: '$current_label' -> '$role'"
    else
      log "Labelling display $index as '$role'"
    fi

    if ! "$YABAI" -m display "$index" \
         --label "$role" >/dev/null 2>&1; then
      warn "could not label display $index as '$role'"
    fi
  done
}


# ----------------------------------------------------------------------
# Determine desired display for a semantic Space
#
# Empty output means:
#
#   preserve the Space wherever it currently lives.
# ----------------------------------------------------------------------

target_display_for_space() {
  local space=$1
  local target=${SPACE_TARGETS[$space]:-}

  [[ -n $target ]] || return 1

  if display_exists "$target"; then
    print -r -- "$target"
    return 0
  fi

  # The desired display is absent, typically because the laptop has
  # been undocked. Do not move or recreate the Space elsewhere.
  return 1
}


# ----------------------------------------------------------------------
# Create one Space and return its new Mission Control index
#
# We identify the new Space by its internal ID rather than assuming
# that it becomes a particular Mission Control index.
# ----------------------------------------------------------------------

create_space() {
  local target=${1:-}

  local -A before=()
  local id index
  local line
  local after_json

  while IFS=$'\t' read -r id index; do
    [[ -n $id ]] && before[$id]=1
  done < <(
    "$YABAI" -m query --spaces id,index 2>/dev/null |
      "$JQ" -r '.[] | [.id, .index] | @tsv'
  )

  if [[ -n $target ]]; then
    log "Creating Space on display '$target'"

    "$YABAI" -m space --create "$target" >/dev/null 2>&1 || {
      warn "could not create Space on display '$target'"
      return 1
    }
  else
    log "Creating Space on active display"

    "$YABAI" -m space --create >/dev/null 2>&1 || {
      warn "could not create Space"
      return 1
    }
  fi

  /bin/sleep 0.15

  after_json=$(
    "$YABAI" -m query --spaces id,index 2>/dev/null
  ) || return 1

  while IFS=$'\t' read -r id index; do
    if [[ -z ${before[$id]-} ]]; then
      print -r -- "$index"
      return 0
    fi
  done < <(
    print -r -- "$after_json" |
      "$JQ" -r '.[] | [.id, .index] | @tsv'
  )

  warn "Space was created but its new index could not be identified"
  return 1
}


# ----------------------------------------------------------------------
# Find or create a Space for one semantic workspace
# ----------------------------------------------------------------------

ensure_semantic_space() {
  local name=$1

  local index
  local target=''
  local candidate=''

  # Existing labelled Space always wins.
  if index=$(space_index_by_label "$name" 2>/dev/null); then
    log "Space '$name' already exists at index $index"
    return 0
  fi

  target=$(target_display_for_space "$name" 2>/dev/null || true)

  # Prefer reusing an existing unlabeled Space rather than creating
  # another macOS Space.
  if (( REUSE_UNLABELED_SPACES )); then

    if [[ -n $target ]]; then
      candidate=$(
        unlabeled_space_on_display "$target" 2>/dev/null ||
          true
      )
    fi

    if [[ -z $candidate ]]; then
      candidate=$(
        first_unlabeled_space 2>/dev/null ||
          true
      )
    fi
  fi

  if [[ -n $candidate ]]; then
    log "Assigning existing Space $candidate -> '$name'"
    index=$candidate
  else
    index=$(create_space "$target") || return 1
    log "Created Space $index for '$name'"
  fi

  if ! "$YABAI" -m space "$index" \
       --label "$name" >/dev/null 2>&1; then
    warn "could not label Space $index as '$name'"
    return 1
  fi

  return 0
}


# ----------------------------------------------------------------------
# Restore desired display placement
#
# If a configured target display is disconnected, no move occurs.
# macOS is therefore free to collapse those Spaces onto the remaining
# display when undocked.
#
# When the display reconnects, this function moves the labelled Spaces
# back to their configured targets.
# ----------------------------------------------------------------------

reconcile_space_display() {
  local name=$1

  local target
  local current_index
  local target_index

  target=$(target_display_for_space "$name" 2>/dev/null) ||
    return 0

  current_index=$(space_display_index "$name" 2>/dev/null) || {
    warn "cannot determine current display for '$name'"
    return 1
  }

  target_index=$(display_index "$target" 2>/dev/null) || {
    warn "cannot resolve display '$target'"
    return 1
  }

  (( current_index == target_index )) && return 0

  log "Moving '$name': display $current_index -> '$target'"

  if ! "$YABAI" -m space "$name" \
       --display "$target" >/dev/null 2>&1; then
    warn "could not move '$name' to display '$target'"
    return 1
  fi

  /bin/sleep 0.1

  return 0
}


# ----------------------------------------------------------------------
# Per-Space layout
# ----------------------------------------------------------------------

reconcile_space_layout() {
  local name=$1
  local layout=${SPACE_LAYOUTS[$name]:-}

  [[ -n $layout ]] || return 0

  case $layout in
    bsp|stack|float)
      ;;
    *)
      warn "invalid layout '$layout' for '$name'"
      return 1
      ;;
  esac

  if ! "$YABAI" -m space "$name" \
       --layout "$layout" >/dev/null 2>&1; then
    warn "could not set '$name' to layout '$layout'"
    return 1
  fi
}


# ----------------------------------------------------------------------
# Topology reconciliation
# ----------------------------------------------------------------------

apply_topology() {
  local name

  # Avoid simultaneous runs from several display/Dock signals.
  if ! /bin/mkdir "$LOCK_DIR" 2>/dev/null; then
    log "Topology reconciliation already running"
    return 0
  fi

  trap '/bin/rmdir "$LOCK_DIR" >/dev/null 2>&1' EXIT INT TERM

  log "Reconciling display topology"

  reconcile_display_labels

  # First establish all nine semantic Space labels.
  for name in $SPACE_NAMES; do
    ensure_semantic_space "$name" ||
      warn "could not establish Space '$name'"
  done

  # Then restore physical-display placement. Using labels here is
  # important because Mission Control indices may change after each
  # move.
  for name in $SPACE_NAMES; do
    reconcile_space_display "$name" ||
      warn "could not reconcile display for '$name'"
  done

  # Finally enforce the intended workspace layout.
  for name in $SPACE_NAMES; do
    reconcile_space_layout "$name" ||
      warn "could not reconcile layout for '$name'"
  done

  log "Topology reconciliation complete"
}


# ----------------------------------------------------------------------
# Human-readable diagnostics
# ----------------------------------------------------------------------

show_displays() {
  print
  print -- "Displays"
  print -- "--------"

  "$YABAI" -m query --displays |
    "$JQ" -r '
      sort_by(.index)[]
      | [
          ("index=" + (.index | tostring)),
          ("label=" + (if .label == "" then "-" else .label end)),
          ("uuid=" + .uuid),
          ("frame=" +
            (.frame.w | tostring) + "x" +
            (.frame.h | tostring) + "+" +
            (.frame.x | tostring) + "+" +
            (.frame.y | tostring)),
          ("spaces=" + (.spaces | map(tostring) | join(",")))
        ]
      | join("  ")
    '

  print
}


show_spaces() {
  print
  print -- "Spaces"
  print -- "------"

  "$YABAI" -m query --spaces |
    "$JQ" -r '
      sort_by(.index)[]
      | [
          ("index=" + (.index | tostring)),
          ("display=" + (.display | tostring)),
          ("label=" + (if .label == "" then "-" else .label end)),
          ("layout=" + .type),
          ("windows=" + (.windows | length | tostring))
        ]
      | join("  ")
    '

  print
}


show_semantic_status() {
  local name
  local index display target layout

  print
  print -- "Semantic topology"
  print -- "-----------------"

  for name in $SPACE_NAMES; do

    index=$(space_index_by_label "$name" 2>/dev/null || true)

    if [[ -n $index ]]; then
      display=$(space_display_index "$name" 2>/dev/null || true)
    else
      display='-'
    fi

    target=${SPACE_TARGETS[$name]:--}
    layout=${SPACE_LAYOUTS[$name]:--}

    printf '%-15s index=%-3s display=%-3s target=%-12s layout=%s\n' \
      "$name" \
      "${index:--}" \
      "${display:--}" \
      "$target" \
      "$layout"
  done

  print
}


show_status() {
  show_displays
  show_spaces
  show_semantic_status
}


# ----------------------------------------------------------------------
# Dispatcher
# ----------------------------------------------------------------------

typeset command=${1:-apply}

case $command in
  apply)
    apply_topology
    ;;

  status)
    show_status
    ;;

  displays)
    show_displays
    ;;

  *)
    print -ru2 -- "usage: ${0:t} [apply|status|displays]"
    exit 64
    ;;
esac
