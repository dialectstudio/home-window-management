# Deployment

## Ownership model

`scripts/managed-paths` is the only deployment manifest. Each non-comment row is:

```text
mode|owner|state|repository-and-config-relative-path
```

`active` and `manual` paths are linked individually from this repository into
`$HOME/.config`. `dormant` paths remain tracked but are not installed. Local
overlays and unrelated files in the four configuration trees are never owned.

Set `WINDOW_MANAGEMENT_CONFIG_HOME` to test against another config root. Normal
operation defaults to `${XDG_CONFIG_HOME:-$HOME/.config}`.

## Preflight

```sh
make check
make test
make status
```

`make status` is an informational report and does not fail merely because paths
are missing or conflicting. `scripts/status.zsh` is the strict form used by
automation and exits nonzero until every deployed manifest path is an exact link
to this checkout and every source mode matches the manifest.

## Install

The default install refuses every conflicting regular file, directory, or link:

```sh
make install
```

To preserve conflicts in a timestamped directory before linking:

```sh
scripts/install.zsh --backup
```

Backups are placed under
`$HOME/.config/.home-window-management-backups/<timestamp>/`. The script
preflights all conflicts before changing any path, is idempotent, and never
links an entire app directory.

Create required local overlays from the examples after installation. Do not
link or commit the real files; see `docs/local-overrides.md`.

## Reload

Install does not reload services. Reload first runs the same validation as
`make check`, then requires `make status` to succeed:

```sh
make reload
```

The reload order is yabai, skhd, SketchyBar, borders. To reload only selected
applications while retaining dependency order:

```sh
scripts/reload.zsh yabai sketchybar
```

The commands preserve the existing service arrangement:

| App | Command |
| --- | --- |
| yabai | `/usr/local/bin/yabai --restart-service` |
| skhd | Signal a running instance with `/usr/local/bin/skhd --reload`; use `--start-service` when its installed native launch agent is unloaded. Restart a running KeyClu afterward so it rereads `skhdrc`. |
| SketchyBar | `/usr/local/bin/sketchybar --reload` |
| borders | `/usr/local/bin/brew services restart borders` |

## Smoke checks

1. Use one directional focus shortcut and one direct workspace shortcut.
2. Change spaces and confirm SketchyBar highlights the canonical workspace and
   updates the focused application label.
3. Create or close a window and confirm the space and yabai items refresh.
4. Focus included and excluded applications and visually inspect borders.
5. Exercise only the bar item or click action changed by the deployment.

## Status and uninstall

```sh
make status
make uninstall
```

Uninstall removes only links that resolve to the corresponding manifest source.
Conflicting files, foreign links, local overlays, backup trees, secrets, and
unrelated files are left unchanged. Empty directories are also left in place.

## Rollback

1. Run `make uninstall`.
2. Move the desired files from the timestamped backup tree to their original
   paths.
3. Reload only the affected services using the table above.

No lifecycle command modifies the existing yabai scripting-addition sudoers
entry. `yabai/maintenance/update.zsh` is a separate explicit manual operation.
