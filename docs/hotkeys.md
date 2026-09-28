# Hotkeys

`skhd/skhdrc` is canonical. This inventory groups repeated directional and
numeric bindings while naming every active chord. KeyClu annotations in the
configuration provide the displayed categories and descriptions.

## Modifier policy

| Layer | Purpose |
| --- | --- |
| Cmd+Alt+Shift | Application launchers |
| Cmd+Alt | New windows and utilities |
| Alt+Shift | Focus, direct workspace navigation, and basic window actions |
| Ctrl+Alt+Shift | Warp, send, and resize windows |
| Ctrl+Alt | User command launchers |
| Cmd+Ctrl+Alt | Service, layout, and reference controls |
| Cmd+Ctrl+Alt+Shift | KeyClu-only reference no-ops |

## Application launchers

| Chord | Target workspace | Application |
| --- | --- | --- |
| Cmd+Alt+Shift+A | 7 | Airmail |
| Cmd+Alt+Shift+C | 7 | Calendar |
| Cmd+Alt+Shift+D | 4 | DEVONthink |
| Cmd+Alt+Shift+E | 6 | Firefox Developer Edition |
| Cmd+Alt+Shift+F | 6 | Firefox |
| Cmd+Alt+Shift+G | 3 | Google Chrome |
| Cmd+Alt+Shift+J | 2 | Day One |
| Cmd+Alt+Shift+K | 9 | Screen Sharing |
| Cmd+Alt+Shift+M | 1 | Music |
| Cmd+Alt+Shift+N | 1 | PlexAmp |
| Cmd+Alt+Shift+O | 2 | Obsidian |
| Cmd+Alt+Shift+P | 1 | System Settings |
| Cmd+Alt+Shift+S | 2 | Sublime Text |
| Cmd+Alt+Shift+T | Current | Terminal |
| Cmd+Alt+Shift+W | 9 | Windows App |
| Cmd+Alt+Shift+X | 8 | FaceTime |
| Cmd+Alt+Shift+Y | 9 | YouTube |
| Cmd+Alt+Shift+Z | 8 | zoom.us |
| Cmd+Alt+Shift+0 | 1 | Disk Utility |

## Windows and utilities

| Chord | Action | Owner/dependency |
| --- | --- | --- |
| Cmd+Alt+C / Cmd+Alt+P | Open/manage ChatGPT projects | External `$HOME/bin/chatgpt-projects` |
| Cmd+Alt+F | New Finder window at Home | AppleScript |
| Cmd+Alt+G | New Chrome window | AppleScript |
| Cmd+Alt+I | New iTerm window | AppleScript; may conflict with browser developer tools |
| Cmd+Alt+S | New Sublime Text window | AppleScript/System Events |
| Ctrl+Alt+C | Open control-file picker | External `$HOME/bin/configctl` |
| Ctrl+Alt+D | Open development project launcher | External `$HOME/bin/dev` |

## yabai actions

| Chords | Action |
| --- | --- |
| Alt+Shift+H/J/K/L | Focus west/south/north/east |
| Alt+Shift+N/B | Focus next/previous with wraparound |
| Alt+Shift+1..9 | Focus canonical workspace 1..9 |
| Alt+Shift+0 | Balance two-window BSP split |
| Alt+Shift+`[` / `]` | Give left/right window one third |
| Alt+Shift+F | Toggle float |
| Alt+Shift+R | Toggle float and center in a 4x4 grid |
| Alt+Shift+Z | Toggle fullscreen zoom |
| Cmd+Ctrl+Alt+Backslash | Run yabai-owned workspace layout toggle |
| Ctrl+Alt+Shift+H/J/K/L | Warp west/south/north/east |
| Ctrl+Alt+Shift+1..9 | Send window to canonical workspace 1..9 and follow |
| Ctrl+Alt+Shift+Arrow keys | Resize by 50 px with opposite-edge fallback |

## Service and reference controls

| Chord | Action |
| --- | --- |
| Cmd+Ctrl+Alt+B | Restart borders through Homebrew |
| Cmd+Ctrl+Alt+S | Reload SketchyBar |
| Cmd+Ctrl+Alt+K | Reload skhd and refresh KeyClu's skhd data |
| Cmd+Ctrl+Alt+Y | Restart yabai |
| Cmd+Ctrl+Alt+R | Show the KeyClu skhd panel |
| Cmd+Ctrl+Alt+8 / H | KeyClu reference no-ops for macOS shortcuts |
| Cmd+Ctrl+Alt+Shift+H / V / N / C / Backslash / M | KeyClu reference no-ops for application shortcuts |

No exact duplicate active chord exists. Reference no-ops intentionally consume
their chords globally and should be reviewed before adding Hyper-style bindings.
