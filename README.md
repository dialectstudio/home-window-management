# macOS Window Management

An opinionated, safely deployable macOS window-management environment built
around [yabai](https://github.com/koekeishiya/yabai),
[skhd](https://github.com/koekeishiya/skhd),
[SketchyBar](https://github.com/FelixKratz/SketchyBar), and
[borders](https://github.com/FelixKratz/JankyBorders).

This repository is the source of truth for one working macOS 15.7.7 setup. It
coordinates semantic workspaces, keyboard-driven window control, an event-aware
menu bar, and focused-window borders while keeping deployment reversible and
machine-local data out of Git. It is both a maintained personal configuration
and a practical reference for building an integrated setup from these tools.

## Highlights

- Nine semantic workspaces are defined once in `yabai/workspaces.tsv` and
  consumed by yabai, skhd, and SketchyBar.
- skhd provides consistent layers for launching applications, focusing and
  moving windows, switching workspaces, changing layouts, and reloading
  services.
- SketchyBar reflects workspace and window state through native events and
  documented yabai signals, with optional weather, calendar, audio, music,
  network-location, and system-status integrations.
- A manifest-driven installer links individual managed files without taking
  ownership of an entire `~/.config` directory.
- Install, status, reload, and uninstall operations are explicit, idempotent,
  and designed to preserve unrelated local files.
- Local topology, service endpoints, API credentials, logs, caches, and other
  runtime state remain outside version control.
- Static checks and isolated lifecycle tests cover shell syntax, manifest
  integrity, file modes, deployment conflicts, backups, and uninstall safety.

## Architecture

Each application has a defined responsibility:

| Component | Responsibility |
| --- | --- |
| yabai | Owns workspaces, window rules, layouts, placement, and event signals. |
| skhd | Owns keyboard bindings and delegates window-management policy to yabai. |
| SketchyBar | Displays state, handles bar interactions, and consumes native or documented custom events. |
| borders | Draws focused-window borders independently of the other applications. |

The central data and event flow is:

```text
yabai/workspaces.tsv
        |
        +--> yabai labels, layouts, placement, and default focus
        +--> skhd workspace navigation assumptions
        +--> SketchyBar workspace items

yabai signals --> yabai_window_change --> SketchyBar space/layout refresh
SketchyBar clicks ---------------------> yabai focus/layout commands
skhd hotkeys --------------------------> yabai commands and helpers
```

Cross-application commands, event payloads, timing assumptions, and failure
behavior are documented in `docs/interactions.md`.

## Supported Environment

The configuration currently targets:

- macOS 15.7.7
- zsh 5.9 at `/bin/zsh`
- Intel Homebrew at `/usr/local`
- Bash 5.3 or newer at `/usr/local/bin/bash`
- yabai, skhd, SketchyBar, borders, and jq installed under `/usr/local/bin`

Several bar items have optional integrations, including `icalBuddy`,
`terminal-notifier`, SwitchAudioSource, KeyClu, Plexamp, and Raycast. macOS
Accessibility, Input Monitoring, Automation, calendar, and Do Not Disturb data
permissions are required only where described in `docs/dependencies.md`.

This project preserves an already configured yabai scripting addition, but it
does not install or modify sudoers rules, System Integrity Protection settings,
launchd jobs, or the user's service manager.

## Quick Start

Read `docs/dependencies.md` and `docs/deployment.md` before changing a live
configuration. Then clone and validate the repository:

```sh
git clone https://github.com/dialectstudio/home-window-management.git
cd home-window-management
make check
make test
make status
```

`make status` is informational and will normally report missing paths before the
first installation. Review `scripts/managed-paths`, then install the managed
files:

```sh
make install
```

The default installer refuses conflicting files. To preserve conflicts in a
timestamped backup before linking, use:

```sh
scripts/install.zsh --backup
```

Create any required local overlays from the tracked `.example` files, then
validate the deployed links and reload the services:

```sh
make status
make reload
```

Installation and reload are deliberately separate. Follow the smoke checks in
`docs/deployment.md` after reloading.

## Commands

| Command | Purpose |
| --- | --- |
| `make check` | Validate shell syntax, skhd command bodies, the manifest, modes, and documentation contracts. |
| `make test` | Exercise installation, conflicts, backups, status, and uninstall in an isolated temporary config root. |
| `make status` | Report the state of every managed path without changing it. |
| `make install` | Link active and manual manifest paths, refusing conflicts. |
| `make reload` | Validate first, then reload yabai, skhd, SketchyBar, and borders in dependency order. |
| `make uninstall` | Remove only links that resolve to this checkout. |

All lifecycle commands act only on paths declared in `scripts/managed-paths`.
Unrelated files, local overlays, secrets, backup trees, and foreign links are
left alone.

## Customization

### Workspaces

Edit `yabai/workspaces.tsv` to change workspace labels, layouts, default-focus
applications, or placement rules. It is the canonical workspace model; review
yabai, skhd, and SketchyBar together after changing it. Physical display UUIDs
and workspace-to-display assignments belong in ignored
`yabai/topology.local.zsh`, based on the tracked example.

### Hotkeys

`skhd/skhdrc` is canonical for bindings. The active chords and modifier policy
are listed in `docs/hotkeys.md`. Some launcher bindings intentionally call user
commands outside this repository; those dependencies are identified in
`docs/dependencies.md`.

### SketchyBar

`sketchybar/sketchybarrc` loads shared colors, icons, logging, custom events, and
items. Active item behavior, update frequency, click actions, and optional
dependencies are inventoried in `docs/interactions.md`. Dormant imported items
remain available as reference but are not deployed by the manifest.

### Local Data and Secrets

Tracked examples describe weather, Plex, and display-topology configuration.
Real local files and credentials are ignored and are never installed from this
repository. See `docs/local-overrides.md` for file locations, supported
environment variables, runtime state, and recommended permissions.

## Repository Layout

```text
home-window-management/
├── AGENTS.md                         # repository contribution constraints
├── LICENSE                           # MIT license
├── Makefile                          # lifecycle entry points
├── README.md
├── borders/                          # ~/.config/borders
├── sketchybar/                       # ~/.config/sketchybar
│   ├── config/                       # sanitized local-overlay examples
│   ├── items/                        # sourced Bash files
│   └── plugins/                      # executable helpers
├── skhd/                             # ~/.config/skhd
├── yabai/                            # ~/.config/yabai
│   ├── maintenance/                  # explicit manual maintenance
│   └── scripts/                      # yabai-owned commands
├── scripts/                          # repository lifecycle commands
├── tests/                            # isolated lifecycle tests
└── docs/                             # contracts and operating procedures
```

Application directories mirror managed paths relative to `$HOME/.config`, but
deployment is file-based. No whole-directory symlink is created.

## Documentation

- `docs/dependencies.md`: required and optional software and macOS permissions
- `docs/deployment.md`: install, status, reload, uninstall, rollback, and smoke tests
- `docs/hotkeys.md`: active skhd binding inventory
- `docs/interactions.md`: event and command contracts across applications
- `docs/local-overrides.md`: local configuration, secrets, and runtime state
- `docs/workspaces.md`: canonical workspace schema and assignments
- `docs/backlog.md`: deferred behavior changes and known defects

## Contributing

Contributions are welcome. Useful areas include portability across macOS and
Homebrew environments, safer lifecycle tooling, clearer documentation, focused
plugin improvements, and additional non-destructive tests.

Before opening a pull request:

1. Read `AGENTS.md` and any app-specific `AGENTS.md` in the directory you edit.
2. Keep changes within the documented ownership boundaries between applications.
3. Update the relevant interaction, dependency, hotkey, or deployment contract.
4. Keep machine-specific values, secrets, logs, caches, and generated state out
   of Git.
5. Run `make check` and `make test`.

Bug reports and focused feature proposals are also welcome through GitHub
Issues. Please include the macOS version, Homebrew prefix, affected component,
reproduction steps, and sanitized command output where relevant.

## License

Original code and documentation in this repository are available under the MIT
License. See `LICENSE`. Third-party projects and materials retain their own
copyright and license terms.
