---
author: T. G. Kelemen
title: coding project - skhd
comment: project instructions;
subject: keyboard bindings
description: Local instructions for skhd.
keywords: macOS; skhd; yabai; hotkeys;
organization: dialectStudio, LLC
copyright: Coding project © 2026 dialectStudio, LLC; underlying source text and third-party materials remain the property of their respective rights holders.
---

# skhd

Follow the root `AGENTS.md`. This directory owns `skhdrc` and app-only includes. `skhdrc` uses skhd syntax, not shell syntax; syntax-check only commands or scripts it calls. Simple one-step yabai actions may remain direct, but branching, query-driven decisions, and multi-step layout policy belong in yabai-owned helpers or genuinely shared commands.

For every change, check duplicate active bindings, KeyClu metadata, macOS/application conflicts, and external dependencies. Keep the canonical binding inventory in `docs/hotkeys.md`, external commands in `docs/dependencies.md`, and cross-app actions in `docs/interactions.md`. Use the reload procedure in `docs/deployment.md` rather than relying only on a hotkey inside the file being reloaded.

The existing setup uses KeyClu (`/Applications/KeyClu.app`) to show macOS and application hotkeys. The current `skhdrc` annotations expose the custom bindings in a panel opened with Cmd+Ctrl+Alt+R.
