#!/bin/zsh

emulate -LR zsh
setopt nounset pipefail errexit

typeset -gr REPO_ROOT=${0:A:h:h}
typeset -gr TEST_ROOT=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/home-window-management-test.XXXXXX")
trap '/bin/rm -rf "$TEST_ROOT"' EXIT

export WINDOW_MANAGEMENT_CONFIG_HOME="$TEST_ROOT/config"

typeset -gr VALID_SKHDRC="$TEST_ROOT/valid-skhdrc"
typeset -gr INVALID_SKHDRC="$TEST_ROOT/invalid-skhdrc"
typeset -gr INVALID_SKHD_COMMAND="$TEST_ROOT/invalid-skhd-command"
print -r -- 'cmd + alt - a : /usr/bin/true' > "$VALID_SKHDRC"
print -r -- 'cmd + alt - \ : /usr/bin/true' > "$INVALID_SKHDRC"
print -r -- 'cmd + alt - a : if' > "$INVALID_SKHD_COMMAND"
"$REPO_ROOT/scripts/check-skhdrc.zsh" "$VALID_SKHDRC"
if "$REPO_ROOT/scripts/check-skhdrc.zsh" "$INVALID_SKHDRC" >/dev/null 2>&1; then
  print -ru2 -- "skhd checker unexpectedly accepted an invalid key literal"
  exit 1
fi
if "$REPO_ROOT/scripts/check-skhdrc.zsh" "$INVALID_SKHD_COMMAND" >/dev/null 2>&1; then
  print -ru2 -- "skhd checker unexpectedly accepted an invalid command body"
  exit 1
fi

"$REPO_ROOT/scripts/install.zsh" >/dev/null
"$REPO_ROOT/scripts/status.zsh" >/dev/null
"$REPO_ROOT/scripts/install.zsh" >/dev/null

/bin/mkdir -p "$WINDOW_MANAGEMENT_CONFIG_HOME/sketchybar"
print -r -- "unrelated" > "$WINDOW_MANAGEMENT_CONFIG_HOME/sketchybar/local-only.conf"

"$REPO_ROOT/scripts/uninstall.zsh" >/dev/null
[[ -f "$WINDOW_MANAGEMENT_CONFIG_HOME/sketchybar/local-only.conf" ]]

print -r -- "conflict" > "$WINDOW_MANAGEMENT_CONFIG_HOME/skhd/skhdrc"
if "$REPO_ROOT/scripts/install.zsh" >/dev/null 2>&1; then
  print -ru2 -- "install unexpectedly replaced a conflict"
  exit 1
fi

"$REPO_ROOT/scripts/install.zsh" --backup >/dev/null
"$REPO_ROOT/scripts/status.zsh" >/dev/null
"$REPO_ROOT/scripts/uninstall.zsh" >/dev/null

typeset -gr SYMLINK_CONFIG="$TEST_ROOT/symlink-config"
typeset -gr EXTERNAL_DIR="$TEST_ROOT/external-sketchybar"
/bin/mkdir -p "$SYMLINK_CONFIG" "$EXTERNAL_DIR"
/bin/ln -s "$EXTERNAL_DIR" "$SYMLINK_CONFIG/sketchybar"
export WINDOW_MANAGEMENT_CONFIG_HOME="$SYMLINK_CONFIG"

if "$REPO_ROOT/scripts/install.zsh" --backup >/dev/null 2>&1; then
  print -ru2 -- "install unexpectedly traversed a parent-directory symlink"
  exit 1
fi
[[ -z "$(/bin/ls -A "$EXTERNAL_DIR")" ]]

export WINDOW_MANAGEMENT_CONFIG_HOME=/dev/null
if "$REPO_ROOT/scripts/install.zsh" >/dev/null 2>&1; then
  print -ru2 -- "install unexpectedly accepted a non-directory config root"
  exit 1
fi

print -r -- "lifecycle tests passed"
