---
author: T. G. Kelemen
title: coding project - yabai
comment: project instructions;
subject: window and space policy
description: Local instructions for yabai.
keywords: macOS; yabai; skhd; sketchybar; shell;
organization: dialectStudio, LLC
copyright: Coding project © 2026 dialectStudio, LLC; underlying source text and third-party materials remain the property of their respective rights holders.
---

# yabai

Follow the root `AGENTS.md`. This directory owns `yabairc`, `scripts/`, `maintenance/`, `focus-default-app.zsh`, portable topology logic, and `workspaces.tsv`.

- Keep layout, window rules, named spaces, and signals here. Review skhd callers and SketchyBar consumers before changing a rule, workspace index, or signal.
- Derive labels, order, layouts, default-focus apps, and placement rules from `workspaces.tsv`, documented in `docs/workspaces.md`. Do not relabel spaces elsewhere.
- Keep physical display identifiers in ignored `topology.local.zsh`; maintain only the sanitized `topology.local.zsh.example` in Git.
- Keep labeled rules and signals idempotent. Document signal environment, payload, timing, and consumers in `docs/interactions.md`.
- Routine install/check scripts may preserve the existing scripting-addition behavior but must not provision or modify sudoers. `maintenance/update.zsh` is an explicit manual operation, not routine deployment.
- Run non-mutating `/bin/zsh -n` checks before live rule, workspace, or signal verification.
