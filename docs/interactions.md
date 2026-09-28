# Interaction contracts

Last audited: 2026-09-26

This registry describes active contracts among borders, SketchyBar, skhd, and
yabai. Repository paths are relative to the root. Local overlays and secrets are
documented in `docs/local-overrides.md`.

## Runtime entry points

| Owner | Entry point | Contract |
| --- | --- | --- |
| yabai | `yabai/yabairc` | Executable zsh; configures workspaces, rules, layouts, and labeled signals. |
| SketchyBar | `sketchybar/sketchybarrc` | Executable Bash; sets logging, loads styles, registers custom events, then sources items. |
| skhd | `skhd/skhdrc` | skhd DSL; command bodies execute through `$SHELL -c`. |
| borders | `borders/bordersrc` | Executable zsh; starts borders independently of yabai and SketchyBar. |

## Workspace contract

`yabai/workspaces.tsv` is the only definition of workspace indices, labels,
layouts, default-focus applications, and placement applications. `yabairc`,
`focus-default-app.zsh`, `topology.zsh`, and the SketchyBar space item consume
it. skhd's numeric bindings assume its order remains stable. Details are in
`docs/workspaces.md`.

## yabai signals

yabai runs signal actions through `/usr/bin/env sh -c`. `yabairc` removes an
existing signal label before adding it, making registration idempotent.

| Signal label / event | Consumer and action | Environment and timing | Failure behavior | Source |
| --- | --- | --- | --- | --- |
| `load-sa-on-dock-restart` / `dock_did_restart` | Reload existing yabai scripting addition. | Immediate; relies on the pre-existing noninteractive sudoers/hash setup. | Event output is suppressed. Initial load separately warns. | `yabai/yabairc:182-197` |
| `focus-default-app-on-space-change` / `space_changed` | Run `focus-default-app.zsh`. | Consumes `YABAI_SPACE_INDEX`; waits 0.05 seconds before querying windows. | Missing helper prevents registration. No matching app is normally a no-op; Home falls back to Finder activation. | `yabai/yabairc`; `yabai/focus-default-app.zsh` |
| `sketchybar-space-changed` / `space_changed` | Trigger custom `yabai_window_change`. | Immediate; no payload forwarded. | SketchyBar errors are suppressed. | `yabai/yabairc` |
| `sketchybar-window-focused` / `window_focused` | Trigger custom `yabai_window_change`. | Immediate; `YABAI_WINDOW_ID` is discarded. | SketchyBar errors are suppressed. | `yabai/yabairc` |
| Window created/destroyed/moved | Trigger custom `yabai_window_change`. | Delayed 0.1 seconds so yabai state can settle; event data is discarded. | Errors are suppressed; bursts are not debounced. | `yabai/yabairc` |
| Application launched/terminated | Trigger custom `yabai_window_change`. | Delayed 0.1 seconds; process data is discarded. | Errors are suppressed; bursts are not debounced. | `yabai/yabairc` |
| Initial yabairc load | Trigger custom `yabai_window_change` after signal registration. | No payload. | Suppressed if SketchyBar is unavailable. | `yabai/yabairc` |

`YABAI_WINDOW_ID` is also supported by the manual
`yabai/scripts/float-small-window.zsh`, but no active signal invokes it.

## SketchyBar events

`sketchybar/events.sh` is sourced before every item. It registers all custom
events. `space_windows_change` is native in SketchyBar 2.24.0 and is not
re-registered.

| Event | Type / producer | Payload or environment | Consumers |
| --- | --- | --- | --- |
| `space_windows_change` | Native SketchyBar event | `INFO` contains JSON for the affected space and app windows; current consumers re-query yabai. | Semantic space items and yabai layout item |
| `yabai_window_change` | Custom; triggered by yabai signals | No payload; consumers re-query yabai. | Semantic space items and yabai layout item |
| `alfred_trigger` | Custom; external Alfred producer | No payload; invokes layout toggle. | yabai layout item |
| `update_yabai_icon` | Custom; external producer | No payload; redraw only. | yabai layout item |
| `network_location_changed` | Custom; successful location popup action | No payload; consumers query current Network Location and network/weather state. | Location, network, weather |
| `focus_on` | Custom mapping to `_NSDoNotDisturbEnabledNotification` | Notification `INFO` may be available; plugins use `SENDER`. | DND item and indicator |
| `focus_off` | Custom mapping to `_NSDoNotDisturbDisabledNotification` | Notification `INFO` may be available; plugins use `SENDER`. | DND item and indicator |

Native plugin environment includes `NAME`, `SENDER`, and `CONFIG_DIR`. Clicks
also supply `BUTTON` and `MODIFIER`; value events use `INFO` or `PERCENTAGE` as
documented by SketchyBar.

## SketchyBar commands sent to yabai

| Trigger | Command/query | Assumptions and failure behavior | Source |
| --- | --- | --- | --- |
| Bar startup | Query labels and indices for each TSV workspace. | Missing labels are reported and skipped; no relabeling occurs. | `sketchybar/items/spaces-simple.sh` |
| Space-item update | Query recent/current space and focused application. | Event payload is ignored; failed queries can leave an empty label. | `sketchybar/plugins/app-space-simple.sh` |
| Click noncurrent space | Focus the selected yabai space. | Right- and Shift-click are no-ops; command errors are not displayed. | `sketchybar/plugins/app-space-simple.sh` |
| Click current space | Run `yabai/scripts/cycle-window.zsh prev`. | No usable target is a successful no-op; missing yabai/jq exits nonzero. | `sketchybar/plugins/app-space-simple.sh` |
| Yabai item refresh | Query current layout, focused-window state, optional stack index, and space-item highlight color. | Missing focused window can produce empty state. | `sketchybar/plugins/yabai.sh` |
| Yabai item click / Alfred | Change BSP to stack, otherwise change to BSP, then redraw. | A floating space becomes BSP. | `sketchybar/plugins/yabai.sh` |
| DND refresh | Query current and all space indices before hiding noncurrent items. | Failed queries contribute no space items; restoration uses temporary state. | `sketchybar/plugins/dnd.sh` |

## Active SketchyBar items

| Item | Script | Events / frequency | Click action | Dependencies / failure behavior |
| --- | --- | --- | --- | --- |
| `yabai` | `plugins/yabai.sh` | Space, front-app, native/custom window events | Toggle BSP/stack | yabai, jq; query failure can leave stale icon |
| `space.N` | `plugins/app-space-simple.sh` | Space, front-app, native/custom window events | Focus space or cycle current-space windows | Canonical TSV, yabai, jq |
| `control_center` | Inline click | None | AppleScript clicks Control Center | Automation/Accessibility; errors discarded |
| `date` | Inline script, 60 s; wake/hover | 60 seconds plus native events | Open Calendar | Calendar app |
| `clock` | `plugins/nextevent.sh`, 10 s; wake/hover | 10 seconds plus native events | Toggle popup and open Calendar | Optional `/usr/local/bin/icalBuddy` |
| `dnd` | `plugins/dnd.sh` | Focus events, click, forced startup update | Toggle configured macOS DND shortcut | Automation, DND database, jq; hidden control is mirrored by indicator |
| `dndindicator` | `plugins/dndindicator.sh`, 60 s | Focus events | Run DND toggle plugin | Same DND dependencies |
| `network` | `plugins/network.sh`, 10 s | Wake and location change | Open System Settings | macOS network tools; offline state shown |
| `volume` / `volume_icon` | `plugins/volume.sh` | Volume and mouse events | Set volume or open/toggle device detail | Optional SwitchAudioSource; missing tool disables device popup only |
| `battery` | `plugins/battery.sh`, 60 s when shown | Power-source and click events | Toggle percentage label | No battery is a no-op |
| `diskmonitor` | `plugins/diskmonitor.sh`, 300 s when shown | Click | Toggle detail or open DaisyDisk | `df`, `bc`, jq |
| `brew` | `plugins/brew.sh`, 300 s | Click | Run explicit Homebrew update/upgrade helper | Homebrew; terminal-notifier optional |
| `weather` | `plugins/weather.sh`, 900 s | Wake and location change | Open Weather | Local config, external key, curl, jq; cache used on transient failure |
| `location` | `plugins/location.sh`, 30 s | Wake and location change | Toggle discovered Network Location popup | `networksetup`; failed switch emits no event |
| `music` | `plugins/music.sh`, 10 s | Click | Open Plexamp or invoke Raycast media action | Plex local overlay/secret optional; unavailable data hides item |

Sourced item files are mode 0644. Executable plugins are mode 0755. Dormant
items and plugins are classified in `scripts/managed-paths` and are not deployed.

## skhd to yabai

| Binding group | Contract | Failure behavior | Source |
| --- | --- | --- | --- |
| Application launchers | Focus a canonical workspace by semantic label, then open an app. | App still opens when focus fails. | `skhd/skhdrc:20-83` |
| Directional focus | Focus west/south/north/east. | No suitable neighbor is a no-op/error. | `skhd/skhdrc:119-131` |
| Window cycle | Focus next/previous with first/last fallback. | Explicit wraparound. | `skhd/skhdrc:134-140` |
| Direct space focus | Map keys 1..9 to canonical semantic labels and focus by label. | Target label must exist. | `skhd/skhdrc:166-193` |
| BSP thirds | Call `space-thirds.zsh` with `even`, `left`, or `right`. | Requires BSP, jq, and two suitable windows. | `skhd/skhdrc:196-205` |
| Basic toggles | Toggle float, centered float grid, or fullscreen zoom. | Direct yabai result. | `skhd/skhdrc:207-214` |
| Space layout | Call yabai-owned `toggle-space-layout.zsh`. | Unknown/query-failed layout exits without changing it. | `skhd/skhdrc`; `yabai/scripts/toggle-space-layout.zsh` |
| Warp | Warp in four directions. | Requires a suitable managed neighbor. | `skhd/skhdrc:225-237` |
| Send and follow | Map keys 1..9 to canonical labels, move the window by label, and focus it. | Requires movable window and target label. | `skhd/skhdrc:240-267` |
| Resize | Resize one edge by 50 px with opposite-edge fallback. | Both failures leave geometry unchanged. | `skhd/skhdrc:270-282` |

## Service controls and borders

| Hotkey | Action |
| --- | --- |
| Cmd+Ctrl+Alt+B | `brew services restart borders` |
| Cmd+Ctrl+Alt+S | `sketchybar --reload` |
| Cmd+Ctrl+Alt+K | Restart KeyClu, then signal the running skhd instance with `skhd --reload`. |
| Cmd+Ctrl+Alt+Y | `yabai --restart-service` |

SketchyBar directory hotload is disabled because it watches every file under
`~/.config/sketchybar`, including local overlays and unmanaged runtime files.
Reloads are explicit through the hotkey above or `scripts/reload.zsh`.

borders has no custom event dependency. It observes ordinary macOS focus changes;
its only cross-app management contract is the skhd service-control hotkey. The
repository reload command restarts KeyClu only when it was already running; this
refreshes KeyClu's cached skhd panel data without making KeyClu mandatory.

## Verification

Run `make check` before deployment. After deployment, use read-only queries:

```sh
/usr/local/bin/yabai -m signal --list | /usr/local/bin/jq '[.[] | {label,event,action}]'
/usr/local/bin/yabai -m query --spaces | /usr/local/bin/jq '[.[] | {index,label,type}]'
/usr/local/bin/sketchybar --query events
/usr/local/bin/sketchybar --query yabai | /usr/local/bin/jq '.scripting'
/usr/local/bin/sketchybar --query space.1 | /usr/local/bin/jq '.scripting'
```

Then perform the smoke checks in `docs/deployment.md`. A successful SketchyBar
reload alone is not sufficient verification.
