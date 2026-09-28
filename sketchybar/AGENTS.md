---
author: T. G. Kelemen
title: coding project - SketchyBar
comment: project instructions;
subject: menu bar and window-management display
description: Local instructions for SketchyBar.
keywords: macOS; sketchybar; yabai; shell;
organization: dialectStudio, LLC
copyright: Coding project © 2026 dialectStudio, LLC; underlying source text and third-party materials remain the property of their respective rights holders.
---

# SketchyBar

Follow the root `AGENTS.md`. This directory owns `sketchybarrc`, shared style/icon libraries, sourced files in `items/`, executable files in `plugins/`, assets, and sanitized examples in `config/`. Keep display and interaction code here.

- Prefer native events when sufficient; use yabai queries or the documented `yabai_window_change` event only for information native events do not provide.
- Register every custom event in `events.sh`, sourced before all item files. Never register custom events in consumers.
- Document each active item's subscriptions, script, update frequency, click action, and optional dependencies in `docs/interactions.md`.
- Keep sourced item/config files non-executable and executable plugins executable as declared by `scripts/managed-paths`.
- Keep credentials, local `.conf` files, logs, caches, temporary artwork/data, archives, backups, and generated `.dat` files out of Git.
- Optional dependencies must emit a bounded warning through `log.sh` and must not stop unrelated items.
- Set `SKETCHYBAR_LOG_LEVEL` near the top of `sketchybarrc`; the generated log path and levels are documented in `docs/local-overrides.md`.
- Do not silently change workspace names, app labels, item update frequencies, or click behavior.

Check modified shell files with `/usr/local/bin/bash -n`, reload as documented in `docs/deployment.md`, and inspect the affected item and click behavior.
