#!/bin/zsh

source "${0:A:h}/lib.zsh"
setopt errexit

typeset mode owner state relative source target

while IFS='|' read -r mode owner state relative; do
  [[ -z $mode || $mode == \#* ]] && continue
  validate_manifest_entry "$mode" "$owner" "$state" "$relative"
  is_deployed_state "$state" || continue
  validate_target_parent "$relative"

  source=$(source_path "$relative")
  target=$(target_path "$relative")

  if is_owned_link "$source" "$target"; then
    /bin/rm "$target"
    print -r -- "removed $target"
  elif [[ -e $target || -L $target ]]; then
    print -r -- "left unowned path unchanged: $target"
  fi
done < "$MANIFEST"
