#!/bin/zsh

# ~/.config/yabai/maintenance/update.zsh
#
# Update the Homebrew-managed yabai installation and refresh the
# scripting-addition SHA-256 entry in /private/etc/sudoers.d/yabai.
#
# Usage:
#   update.zsh
#   update.zsh release
#   update.zsh head
#
# Default:
#   release
#
# Environment:
#   YABAI_CERT
#       Code-signing certificate used for HEAD builds.
#       Default: yabai-cert

emulate -LR zsh
setopt nounset pipefail errexit

typeset -gr BREW=/usr/local/bin/brew
typeset -gr YABAI=/usr/local/bin/yabai
typeset -gr JQ=/usr/local/bin/jq

typeset -gr FORMULA=asmvik/formulae/yabai
typeset -gr SUDOERS_FILE=/private/etc/sudoers.d/yabai
typeset -gr YABAI_CERT=${YABAI_CERT:-yabai-cert}

typeset mode=${1:-release}

case $mode in
  release|head)
    ;;
  *)
    print -ru2 -- "usage: ${0:t} [release|head]"
    exit 64
    ;;
esac

[[ -x $BREW ]] || {
  print -ru2 -- "update: Homebrew not found: $BREW"
  exit 69
}

[[ -x $JQ ]] || {
  print -ru2 -- "update: jq not found: $JQ"
  exit 69
}

log() {
  print -r -- "==> $*"
}

warn() {
  print -ru2 -- "warning: $*"
}

die() {
  print -ru2 -- "error: $*"
  exit 1
}


# ----------------------------------------------------------------------
# Preserve existing Homebrew pin state
# ----------------------------------------------------------------------

typeset -i was_pinned=0

if "$BREW" list --pinned 2>/dev/null |
     /usr/bin/grep -qx 'yabai'; then

  was_pinned=1

  log "Temporarily unpinning yabai"
  "$BREW" unpin yabai
fi


restore_pin() {
  if (( was_pinned )) &&
     "$BREW" list --formula 2>/dev/null |
       /usr/bin/grep -qx 'yabai'; then

    log "Restoring yabai Homebrew pin"
    "$BREW" pin yabai >/dev/null
  fi
}

trap restore_pin EXIT


# ----------------------------------------------------------------------
# Detect current Homebrew installation type
# ----------------------------------------------------------------------

installed_version() {
  "$BREW" info --json=v2 "$FORMULA" 2>/dev/null |
    "$JQ" -r \
      '.formulae[0].installed[0].version // empty'
}


# ----------------------------------------------------------------------
# Safely update the sudoers SHA-256 value
# ----------------------------------------------------------------------

update_sudoers_hash() {
  [[ -x $YABAI ]] ||
    die "cannot update sudoers: yabai binary not found"

  if [[ ! -f $SUDOERS_FILE ]]; then
    warn "$SUDOERS_FILE does not exist"
    warn "scripting-addition sudoers hash was not updated"

    print -ru2 -- ""
    print -ru2 -- "Create it with:"
    print -ru2 -- ""
    print -ru2 -- \
      "  sudo visudo -f $SUDOERS_FILE"
    print -ru2 -- ""

    return 0
  fi

  typeset hash tmp

  hash=$(
    /usr/bin/shasum -a 256 "$YABAI" |
      /usr/bin/awk '{print $1}'
  )

  [[ -n $hash ]] ||
    die "could not calculate yabai SHA-256"

  tmp=$(/usr/bin/mktemp -t yabai-sudoers)

  {
    /usr/bin/sed -E \
      "s#sha256:[[:xdigit:]]+#sha256:${hash}#g" \
      "$SUDOERS_FILE" > "$tmp"

    /usr/bin/grep -q "sha256:${hash}" "$tmp" ||
      die "existing sudoers file contains no replaceable yabai SHA-256 entry"

    log "Validating updated sudoers entry"

    /usr/bin/sudo /usr/sbin/visudo -cf "$tmp" ||
      die "updated sudoers entry failed validation"

    log "Installing updated yabai sudoers hash"

    /usr/bin/sudo /usr/bin/install \
      -o root \
      -g wheel \
      -m 0440 \
      "$tmp" \
      "$SUDOERS_FILE"

  } always {
    /bin/rm -f "$tmp"
  }
}


# ----------------------------------------------------------------------
# Preparation
# ----------------------------------------------------------------------

log "Ensuring current yabai Homebrew tap"

/usr/local/bin/brew tap asmvik/formulae >/dev/null

typeset current_version=''
current_version=$(installed_version || true)

if [[ -n $current_version ]]; then
  log "Installed yabai: $current_version"
else
  log "No Homebrew yabai installation detected"
fi


# ----------------------------------------------------------------------
# Stop/remove launchd service before changing the binary
# ----------------------------------------------------------------------

if [[ -x $YABAI ]]; then
  log "Stopping yabai service"

  "$YABAI" --stop-service >/dev/null 2>&1 || true

  # Rebuilding the service after an update prevents stale launch-agent
  # paths, which is particularly important when switching to/from HEAD.
  "$YABAI" --uninstall-service >/dev/null 2>&1 || true
fi


# ----------------------------------------------------------------------
# Update/install
# ----------------------------------------------------------------------

case $mode in
  release)

    if [[ -z $current_version ]]; then
      log "Installing yabai release"
      "$BREW" install "$FORMULA"

    elif [[ $current_version == HEAD-* ]]; then
      log "Switching yabai from HEAD to release"

      "$BREW" uninstall --formula yabai
      "$BREW" install "$FORMULA"

    else
      log "Updating yabai release"
      "$BREW" upgrade "$FORMULA"
    fi
    ;;


  head)

    if [[ $current_version == HEAD-* ]]; then
      log "Updating yabai HEAD"
      "$BREW" reinstall "$FORMULA"

    else
      if [[ -n $current_version ]]; then
        log "Switching yabai from release to HEAD"
        "$BREW" uninstall --formula yabai
      else
        log "Installing yabai HEAD"
      fi

      "$BREW" install "$FORMULA" --HEAD
    fi

    typeset head_binary
    head_binary="$("$BREW" --prefix yabai)/bin/yabai"

    [[ -x $head_binary ]] ||
      die "HEAD yabai binary not found: $head_binary"

    log "Code-signing HEAD build using '$YABAI_CERT'"

    /usr/bin/codesign \
      -fs "$YABAI_CERT" \
      "$head_binary"
    ;;
esac


# ----------------------------------------------------------------------
# Scripting addition
# ----------------------------------------------------------------------

log "Updating scripting-addition sudoers hash"

update_sudoers_hash


# ----------------------------------------------------------------------
# Restart yabai
# ----------------------------------------------------------------------

[[ -x $YABAI ]] ||
  die "updated yabai binary not found: $YABAI"

log "Starting yabai service"

"$YABAI" --start-service


# ----------------------------------------------------------------------
# Report
# ----------------------------------------------------------------------

/bin/sleep 1

typeset version
version=$("$YABAI" --version)

log "Update complete: $version"

if (( was_pinned )); then
  log "Yabai will be re-pinned automatically"
fi
