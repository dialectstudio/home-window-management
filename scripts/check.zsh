#!/bin/zsh

source "${0:A:h}/lib.zsh"

typeset -A seen=()
typeset -a bash_files=() zsh_files=() candidate_files=()
typeset mode owner state relative source actual_mode first_line
typeset -i failures=0

while IFS='|' read -r mode owner state relative; do
  [[ -z $mode || $mode == \#* ]] && continue
  validate_manifest_entry "$mode" "$owner" "$state" "$relative"

  if [[ -n ${seen[$relative]-} ]]; then
    print -ru2 -- "duplicate manifest path: $relative"
    (( failures += 1 ))
    continue
  fi
  seen[$relative]=1

  source=$(source_path "$relative")
  if [[ ! -f $source ]]; then
    print -ru2 -- "missing managed source: $relative"
    (( failures += 1 ))
    continue
  fi

  actual_mode=$(file_mode "$source")
  if [[ $actual_mode != ${mode#0} ]]; then
    print -ru2 -- "mode mismatch: $relative expected=${mode#0} actual=$actual_mode"
    (( failures += 1 ))
  fi

  if [[ $relative == sketchybar/*.sh || $relative == sketchybar/**/*.sh ]]; then
    IFS= read -r first_line < "$source"
    if [[ $first_line != '#!/usr/bin/env bash' ]]; then
      print -ru2 -- "invalid SketchyBar shebang: $relative"
      (( failures += 1 ))
    fi
    bash_files+=("$source")
  elif [[ $relative == borders/bordersrc || $relative == yabai/yabairc || $relative == yabai/**/*.zsh || $relative == yabai/*.zsh ]]; then
    zsh_files+=("$source")
  fi
done < "$MANIFEST"

(( ${#bash_files} )) && /usr/local/bin/bash -n "${bash_files[@]}" || (( failures += 1 ))
(( ${#zsh_files} )) && /bin/zsh -n "${zsh_files[@]}" || (( failures += 1 ))

/usr/bin/python3 -c 'import ast, pathlib, sys; p=pathlib.Path(sys.argv[1]); ast.parse(p.read_text(), filename=str(p))' "$REPO_ROOT/sketchybar/plugins/stress.py" || (( failures += 1 ))

while IFS= read -r -d '' relative; do
  candidate_files+=("$REPO_ROOT/$relative")

  if [[ $relative == (borders|sketchybar|skhd|yabai)/* &&
        $relative != */AGENTS.md &&
        $relative != *.example &&
        -z ${seen[$relative]-} ]]; then
    print -ru2 -- "unclassified app source: $relative"
    (( failures += 1 ))
  fi
done < <(/usr/local/bin/git -C "$REPO_ROOT" ls-files --cached --others --exclude-standard -z)

duplicates=$(
  /usr/bin/awk -F: '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    index($0, ":") {
      binding=$1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", binding)
      print binding
    }
  ' "$REPO_ROOT/skhd/skhdrc" | /usr/bin/sort | /usr/bin/uniq -d
)
if [[ -n $duplicates ]]; then
  print -ru2 -- "duplicate skhd bindings:\n$duplicates"
  (( failures += 1 ))
fi

if /usr/bin/grep -q '#KeyClue' "$REPO_ROOT/skhd/skhdrc"; then
  print -ru2 -- "malformed KeyClu annotation found"
  (( failures += 1 ))
fi

"$SCRIPT_DIR/check-skhdrc.zsh" || (( failures += 1 ))

unexpected_events=$(
  /usr/bin/grep -R -n --include='*.sh' -- '--add event' "$REPO_ROOT/sketchybar" |
    /usr/bin/grep -v '/events.sh:' || true
)
if [[ -n $unexpected_events ]]; then
  print -ru2 -- "custom event registration outside events.sh:\n$unexpected_events"
  (( failures += 1 ))
fi

private_paths=""
if (( ${#candidate_files} )); then
  private_paths=$(
    /usr/bin/grep -n -E '/''Users/[^/]+|\.lan''\.internal' "${candidate_files[@]}" 2>/dev/null || true
  )
fi
if [[ -n $private_paths ]]; then
  print -ru2 -- "machine-specific path found:\n$private_paths"
  (( failures += 1 ))
fi

typeset -A workspace_labels=()
typeset -i expected_index=1
typeset index label layout default_app placement
while IFS=$'\t' read -r index label layout default_app placement; do
  if [[ $index != $expected_index || -z $label || -z $layout || -z $default_app || -z $placement ]]; then
    print -ru2 -- "invalid workspace record at index $expected_index"
    (( failures += 1 ))
  fi
  if [[ -n ${workspace_labels[$label]-} ]]; then
    print -ru2 -- "duplicate workspace label: $label"
    (( failures += 1 ))
  fi
  workspace_labels[$label]=1
  (( expected_index += 1 ))
done < "$REPO_ROOT/yabai/workspaces.tsv"

(( failures == 0 )) || exit 1
print -r -- "checks passed"
