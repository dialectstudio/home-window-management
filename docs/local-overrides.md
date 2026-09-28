# Local overrides and runtime state

## File classes

| Class | Tracked | Deployed by manifest | Examples |
| --- | --- | --- | --- |
| Managed source | Yes | Active/manual files only | Entry points, items, plugins, yabai helpers |
| Local overlay | Sanitized `.example` only | No | Weather, Plex, physical display topology |
| Secret | No | No | Weather API key, Plex token |
| Runtime state | No | No | Logs, caches, DND snapshots, artwork, archives |

## Local overlays

| Example | Local file | Purpose |
| --- | --- | --- |
| `sketchybar/config/weather.conf.example` | `sketchybar/config/weather.conf` | Weather query, units, AQI, and per-Network-Location queries |
| `sketchybar/config/plex.conf.example` | `sketchybar/config/plex.conf` | Plex endpoint and token-file path |
| `yabai/topology.local.zsh.example` | `yabai/topology.local.zsh` | Physical display UUIDs and optional workspace targets |

The real files coexist with managed links and are ignored by Git. Keep secret
values out of `.conf` files when a separate token file is supported.

## Secrets

Weather defaults to `${SKETCHYBAR_SECRET_DIR:-$HOME/.dotfiles/secrets}/weather`
unless `WEATHER_SECRET_FILE` overrides it. Plex reads the token file named by
`PLEX_TOKEN_FILE` in the local Plex configuration.

Secret directories should be mode `0700` and secret files mode `0600`. API keys
and tokens must not be added to Git, shell command lines, logs, or examples.

## SketchyBar logging

Set `SKETCHYBAR_LOG_LEVEL` near the top of `sketchybarrc` or in the service
environment. Supported values are `debug`, `info`, `warn`, `error`, and `off`.
The default is `warn`.

The config writes the selected level to a UID-scoped runtime file so separately
invoked plugins use the same setting. `SKETCHYBAR_LOG_FILE` defaults to
`${TMPDIR:-/tmp}/sketchybar-${UID}.log`. This is generated runtime state and is
not managed or committed.

## Other runtime state

- Weather cache, state, and debug files use `${TMPDIR:-/tmp}`.
- Plex artwork uses `${TMPDIR:-/tmp}/sketchybar-plex-artwork.jpg`.
- DND and battery state use UID-scoped `sketchybar-${UID}-*` files under
  `${TMPDIR:-/tmp}`.
- Topology locking uses `/tmp/yabai-topology-${UID}.lock`.
- Sublime `.sublime-workspace`, macOS `.DS_Store`, logs, archives, backups,
  generated `.dat`, Python bytecode, and caches are untracked.
