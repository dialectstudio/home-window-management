#!/bin/zsh

source "${0:A:h}/lib.zsh"
setopt errexit

typeset -i backup=0
if (( $# > 1 )); then
  die "usage: ${0:t} [--backup]"
elif (( $# == 1 )); then
  [[ $1 == --backup ]] || die "usage: ${0:t} [--backup]"
  backup=1
fi

typeset -a conflicts=()
typeset mode owner state relative source target

while IFS='|' read -r mode owner state relative; do
  [[ -z $mode || $mode == \#* ]] && continue
  validate_manifest_entry "$mode" "$owner" "$state" "$relative"
  is_deployed_state "$state" || continue

  source=$(source_path "$relative")
  target=$(target_path "$relative")
  validate_target_parent "$relative"
  [[ -f $source ]] || die "managed source is missing: $relative"
  [[ $(file_mode "$source") == ${mode#0} ]] || die "source mode mismatch: $relative"

  is_owned_link "$source" "$target" && continue
  [[ -e $target || -L $target ]] && conflicts+=("$relative")
done < "$MANIFEST"

if (( ${#conflicts} && ! backup )); then
  print -ru2 -- "refusing to replace conflicting managed paths:"
  printf '  %s\n' "${conflicts[@]}" >&2
  print -ru2 -- "rerun scripts/install.zsh --backup to preserve them first"
  exit 2
fi

typeset backup_root=""
if (( ${#conflicts} )); then
  backup_root="$CONFIG_HOME/.home-window-management-backups/$(/bin/date '+%Y%m%d-%H%M%S')"
fi

while IFS='|' read -r mode owner state relative; do
  [[ -z $mode || $mode == \#* ]] && continue
  is_deployed_state "$state" || continue

  source=$(source_path "$relative")
  target=$(target_path "$relative")
  is_owned_link "$source" "$target" && continue

  typeset previous=""
  if [[ -e $target || -L $target ]]; then
    /bin/mkdir -p "$backup_root/${relative:h}"
    previous="$backup_root/$relative"
    /bin/mv "$target" "$previous"
    print -r -- "backed up $target -> $backup_root/$relative"
  fi

  /bin/mkdir -p "${target:h}"
  if ! /bin/ln -s "$source" "$target"; then
    if [[ -n $previous && ( -e $previous || -L $previous ) ]]; then
      /bin/mv "$previous" "$target"
    fi
    die "could not link $target"
  fi
  print -r -- "linked $target -> $source"
done < "$MANIFEST"

[[ -z $backup_root ]] || print -r -- "backup root: $backup_root"
