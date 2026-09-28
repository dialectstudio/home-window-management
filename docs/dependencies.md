# Dependencies

## Core applications

| Dependency | Expected path | Required for |
| --- | --- | --- |
| borders | `/usr/local/bin/borders` | Focused-window borders |
| SketchyBar | `/usr/local/bin/sketchybar` | Menu bar |
| skhd | `/usr/local/bin/skhd` | Hotkeys |
| yabai | `/usr/local/bin/yabai` | Window and workspace management |
| Homebrew | `/usr/local/bin/brew` | Existing service management and brew item |
| Bash 5.3+ | `/usr/local/bin/bash` | SketchyBar syntax checks and runtime scripts |
| zsh 5.9 | `/bin/zsh` | Lifecycle, borders, and yabai scripts |
| jq | `/usr/local/bin/jq` | yabai and SketchyBar JSON queries |

## Active supporting tools

| Tool | Requirement | Consumer |
| --- | --- | --- |
| `curl` | macOS `/usr/bin/curl` | Weather and optional Plex status |
| `xmllint` | macOS `/usr/bin/xmllint` | Optional Plex XML parsing |
| `networksetup`, `route`, `ifconfig`, `ipconfig` | macOS system tools | Location and network items |
| `osascript` | macOS system tool | Focus fallback, volume, Control Center, DND |
| `bc`, `df` | Command line tools | Disk monitor |
| `icalBuddy` | Optional `/usr/local/bin/icalBuddy` | Next-calendar-event popup |
| `terminal-notifier` | Optional `/usr/local/bin/terminal-notifier` | Brew update notification |
| `SwitchAudioSource` | Optional `/usr/local/bin/SwitchAudioSource` | Audio device detection and switching |
| KeyClu | Optional `/Applications/KeyClu.app` | skhd reference panel |

Missing optional tools disable only their associated behavior and must produce a
bounded SketchyBar warning where applicable.

## External user commands

The following skhd targets are intentionally outside this repository:

| Command | Bindings |
| --- | --- |
| `$HOME/bin/chatgpt-projects` | Cmd+Alt+C, Cmd+Alt+P |
| `$HOME/bin/configctl` | Ctrl+Alt+C |
| `$HOME/bin/dev` | Ctrl+Alt+D |

Their absence does not affect the four managed services, but their bindings fail.

## Applications and fonts

Launcher bindings use the macOS application names recorded in `docs/hotkeys.md`.
SketchyBar icons require the configured Nerd Font in `globalstyles.sh`; SF
Symbols glyphs depend on the current macOS font set. Music actions optionally
use Plexamp and Raycast.

## Permissions

- yabai: Accessibility; the existing scripting-addition sudoers/hash setup for
  features that require it.
- skhd: Accessibility/Input Monitoring.
- SketchyBar plugins: Automation access to System Events, Calendar, and affected
  applications when macOS prompts.
- DND status: read access to the user's Do Not Disturb database.
- Calendar item: calendar database access granted to `icalBuddy` when used.

Routine install and check commands do not create or modify these permissions,
sudoers, system protections, launchd jobs, or service-manager configuration.
Because skhd 0.3.9 has no parse-only option, `make check` statically validates
the direct binding syntax used by this repository and parses every command body
with `/bin/zsh -n`. Reload refuses to proceed when these checks fail.

## Dormant-only dependencies

Dormant imported plugins may require Python 3.14 plus `garth`, Transmission,
Messages/Mail database access, or other app-specific tools. Dormant files are
not deployed and are not part of the supported active runtime.
