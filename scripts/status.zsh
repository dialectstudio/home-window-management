#!/bin/zsh

source "${0:A:h}/lib.zsh"

typeset -i report_only=0
if (( $# > 1 )); then
  die "usage: ${0:t} [--report]"
elif (( $# == 1 )); then
  [[ $1 == --report ]] || die "usage: ${0:t} [--report]"
  report_only=1
fi

typeset -i failures=0
typeset -i linked=0 conflicts=0 missing=0 source_missing=0 mode_mismatches=0
typeset mode owner state relative source target actual_mode

while IFS='|' read -r mode owner state relative; do
  [[ -z $mode || $mode == \#* ]] && continue
  validate_manifest_entry "$mode" "$owner" "$state" "$relative"
  is_deployed_state "$state" || continue

  source=$(source_path "$relative")
  target=$(target_path "$relative")
  validate_target_parent "$relative"

  if [[ ! -f $source ]]; then
    print -r -- "source-missing $relative"
    (( failures += 1 ))
    (( source_missing += 1 ))
    continue
  fi

  actual_mode=$(file_mode "$source")
  if [[ $actual_mode != ${mode#0} ]]; then
    print -r -- "mode-mismatch $relative expected=${mode#0} actual=$actual_mode"
    (( failures += 1 ))
    (( mode_mismatches += 1 ))
  fi

  if is_owned_link "$source" "$target"; then
    print -r -- "linked $relative"
    (( linked += 1 ))
  elif [[ -e $target || -L $target ]]; then
    print -r -- "conflict $relative"
    (( failures += 1 ))
    (( conflicts += 1 ))
  else
    print -r -- "missing $relative"
    (( failures += 1 ))
    (( missing += 1 ))
  fi
done < "$MANIFEST"

print -r -- "summary linked=$linked conflict=$conflicts missing=$missing source-missing=$source_missing mode-mismatch=$mode_mismatches"

if (( failures )); then
  print -r -- "not fully installed; see docs/deployment.md"
fi

(( report_only )) && exit 0
exit $(( failures > 0 ))
