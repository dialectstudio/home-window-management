# Workspaces

`yabai/workspaces.tsv` is the canonical workspace model. Its tab-separated
fields are:

```text
index  label  layout  default-focus-regex-or--  placement-app-regex
```

| Index | Label | Layout | Default focused app |
| --- | --- | --- | --- |
| 1 | Home | float | Finder |
| 2 | Writing | bsp | Sublime Text |
| 3 | Reading | bsp | Google Chrome |
| 4 | Research | bsp | DEVONthink |
| 5 | Development | bsp | iTerm/iTerm2 |
| 6 | MIS | bsp | Firefox or Firefox ESR |
| 7 | Mail/Messages | float | None |
| 8 | Meet | float | None |
| 9 | VM | float | None |

`yabairc` consumes all fields to label/configure spaces and create placement
rules. `focus-default-app.zsh` consumes the index and default-focus regex.
`topology.zsh` consumes labels and layouts. SketchyBar reads the indices and
labels and adds only icon/color display metadata.

skhd maps number-key bindings to these semantic labels, so topology changes may
change Mission Control indices without changing hotkey meaning. Change a record
in the TSV and review yabai, skhd, and SketchyBar together. No consumer may
relabel a workspace independently.

Physical display UUIDs and workspace-to-display targets are machine-local and
belong in ignored `yabai/topology.local.zsh`, based on the tracked example.
