#!/bin/zsh

emulate -LR zsh
setopt nounset pipefail

typeset -gr SCRIPT_DIR=${0:A:h}
typeset -gr REPO_ROOT=${SCRIPT_DIR:h}
typeset -gr CONFIG=${1:-$REPO_ROOT/skhd/skhdrc}
typeset -i failures=0 line_number=0
typeset line trimmed command

[[ -f $CONFIG ]] || {
  print -ru2 -- "missing skhd config: $CONFIG"
  exit 1
}

# skhd 0.3.9 has no parse-only mode. Validate the direct command-binding
# subset used by this repository against skhd's tokenizer vocabulary.
/usr/bin/awk '
  function trim(value) {
    sub(/^[[:space:]]+/, "", value)
    sub(/[[:space:]]+$/, "", value)
    return value
  }

  function report(message) {
    printf "%s:%d: %s\n", FILENAME, FNR, message > "/dev/stderr"
    failed = 1
  }

  function valid_key(key) {
    return key ~ /^[[:alnum:]]$/ || key ~ /^0x[0-9A-F]+$/ || (key in literals)
  }

  BEGIN {
    split("alt lalt ralt shift lshift rshift cmd lcmd rcmd ctrl lctrl rctrl fn hyper meh", values, " ")
    for (i in values) modifiers[values[i]] = 1

    split("return tab space backspace escape delete home end pageup pagedown insert left right up down f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 sound_up sound_down mute play previous next rewind fast brightness_up brightness_down illumination_up illumination_down", values, " ")
    for (i in values) literals[values[i]] = 1
  }

  /^[[:space:]]*(#|$)/ { next }

  {
    separator = index($0, ":")
    if (!separator) {
      report("expected colon followed by a command")
      next
    }

    lhs = trim(substr($0, 1, separator - 1))
    command = trim(substr($0, separator + 1))
    if (!length(command)) report("expected command after colon")

    sub(/[[:space:]]*->[[:space:]]*$/, "", lhs)
    count = split(lhs, action, /[[:space:]]*-[[:space:]]*/)
    if (count != 2) {
      report("expected direct binding: modifiers - key")
      next
    }

    modifier_count = split(trim(action[1]), binding_modifiers, /[[:space:]]*\+[[:space:]]*/)
    for (i = 1; i <= modifier_count; ++i) {
      if (!(binding_modifiers[i] in modifiers)) {
        report("unknown modifier: " binding_modifiers[i])
      }
    }

    key = trim(action[2])
    if (!valid_key(key)) report("invalid key literal: " key "; use an skhd literal or 0x keycode")
  }

  END { exit failed }
' "$CONFIG" || (( failures += 1 ))

while IFS= read -r line || [[ -n $line ]]; do
  (( line_number += 1 ))
  trimmed=${line#"${line%%[![:space:]]*}"}
  [[ -z $trimmed || $trimmed == \#* || $line != *:* ]] && continue

  command=${line#*:}
  if ! /bin/zsh -n -c "$command"; then
    print -ru2 -- "$CONFIG:$line_number: invalid zsh command body"
    (( failures += 1 ))
  fi
done < "$CONFIG"

(( failures == 0 ))
