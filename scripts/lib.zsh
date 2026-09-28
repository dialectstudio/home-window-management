#!/bin/zsh

emulate -LR zsh
setopt nounset pipefail

typeset -gr SCRIPT_DIR=${0:A:h}
typeset -gr REPO_ROOT=${SCRIPT_DIR:h}
typeset -gr MANIFEST="$SCRIPT_DIR/managed-paths"
typeset -gr CONFIG_HOME=${WINDOW_MANAGEMENT_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}

die() {
  print -ru2 -- "error: $*"
  exit 1
}

is_deployed_state() {
  [[ $1 == active || $1 == manual ]]
}

source_path() {
  print -r -- "$REPO_ROOT/$1"
}

target_path() {
  print -r -- "$CONFIG_HOME/$1"
}

is_owned_link() {
  local source=$1 target=$2
  [[ -L $target && ${target:A} == ${source:A} ]]
}

file_mode() {
  /usr/bin/stat -f '%Lp' "$1"
}

validate_manifest_entry() {
  local mode=$1 owner=$2 state=$3 relative=$4

  [[ $mode == (0644|0755) ]] || die "invalid mode '$mode' for $relative"
  [[ $owner == (borders|sketchybar|skhd|yabai) ]] || die "invalid owner '$owner' for $relative"
  [[ $state == (active|manual|dormant) ]] || die "invalid state '$state' for $relative"
  [[ -n $relative && $relative != /* && $relative != *'..'* ]] || die "unsafe manifest path: $relative"
  [[ $relative == "$owner"/* ]] || die "owner/path mismatch: $owner $relative"
}

validate_target_parent() {
  local relative=$1 current=$CONFIG_HOME component
  local parent=${relative:h}

  if [[ -L $CONFIG_HOME ]]; then
    die "refusing config-root symlink: $CONFIG_HOME"
  elif [[ -e $CONFIG_HOME && ! -d $CONFIG_HOME ]]; then
    die "refusing non-directory config root: $CONFIG_HOME"
  fi

  for component in ${(s:/:)parent}; do
    current="$current/$component"
    if [[ -L $current ]]; then
      die "refusing parent-directory symlink: $current"
    elif [[ -e $current && ! -d $current ]]; then
      die "refusing non-directory parent: $current"
    fi
  done
}
