---
author: T. G. Kelemen
title: coding project - macOS window management
comment: project instructions;
subject: borders; sketchybar; skhd; yabai
description: Shared instructions for the macOS window-management configuration repository.
keywords: macOS; shell; window management; borders; sketchybar; skhd; yabai;
organization: dialectStudio, LLC
copyright: Coding project © 2026 dialectStudio, LLC; underlying source text and third-party materials remain the property of their respective rights holders.
---

# Project Instructions

## Purpose and scope

This repository is the source of truth for one macOS 15.7.7 setup comprising borders, SketchyBar, skhd, and yabai. Keep their native configuration paths and preserve existing behavior while migrating. Read `README.md`, relevant app files, `docs/interactions.md`, and Git status before editing. More specific instructions in an app directory apply there.

## Environment

- Interactive shell: `/bin/zsh` 5.9. Use explicit shebangs and do not rely on interactive aliases.
- SketchyBar configuration uses Bash syntax. Declare `#!/usr/bin/env bash` and syntax-check with Homebrew Bash at `/usr/local/bin/bash`.
- Homebrew prefix: `/usr/local`. Prefer `/usr/local/bin/git` for repository operations.
- Sublime Text is the editor. Keep the tracked `.sublime-project` portable; never commit `.sublime-workspace`.
- Store source in this repository, user configuration at `$HOME/.config/<app>/`, and any shared user command at `$HOME/.local/bin/`.

## Repository model

- App directories mirror managed paths relative to `$HOME/.config/<app>/`; this does not authorize whole-directory links.
- `scripts/managed-paths` is the single deployment manifest used by install, status, and uninstall.
- Classify files as managed source, local overlay, secret, or generated runtime state. Track only managed source and sanitized `.example` files.
- `scripts/` owns repository lifecycle commands. `bin/` is reserved for commands invoked by two or more runtime app configurations and must remain absent until needed.
- Preserve the executable bit declared by the manifest for entry points and executable helpers/plugins.
- Use `docs/dependencies.md`, `docs/deployment.md`, and `docs/local-overrides.md` as the canonical operational references.

## Boundaries between apps

- yabai owns window rules, spaces, layout, and signals.
- skhd owns key bindings and calls yabai or shared commands; do not duplicate window-management logic in hotkey actions.
- SketchyBar owns display and interaction. Document every event it consumes from yabai and every command it sends to yabai. Prefer native SketchyBar events where sufficient.
- borders owns focused-window border appearance; keep it independent unless an actual integration is needed.
- Shared multi-app logic belongs in `bin/` only when more than one configuration needs it. Record the event or command contract in `docs/interactions.md`.
- `yabai/workspaces.tsv` is the single canonical workspace model. Consumers may add display metadata but must not redefine or relabel its indices and semantic names.
- Register custom SketchyBar events centrally before any subscription. Record producers, event names, payload/environment, timing assumptions, and consumers in `docs/interactions.md`.

## Changes and deployment

1. Inspect installed config, repository version, and `git status` before editing; preserve uncommitted changes.
2. Make a small change at its owner, then review callers and event consumers in the other apps.
3. Syntax-check shell files with their declared interpreter. Treat `skhdrc` as skhd DSL, not a shell script. Validate executable permissions where necessary.
4. Test changed commands without disturbing live window state when possible; check one live interaction after deployment.
5. Deploy only through a documented, idempotent command that backs up or refuses conflicting targets, links the intended files, and leaves unrelated files alone. Do not overwrite the four existing `~/.config` trees blindly.
6. Reload only affected services, in dependency order when several change: yabai, skhd, SketchyBar, borders. Preserve the user's existing service manager and permissions setup.
7. Document new dependencies, hotkeys, yabai signals, SketchyBar event names, and macOS permission requirements.

Preserving the already configured yabai scripting addition is allowed. Do not install or change its sudoers/system-protection setup, add another `sudo` requirement, add a service manager, or add launchd files without a demonstrated need and an explicit task. Do not commit tokens, machine-specific paths, logs, caches, or generated state. Never discard user changes, force-push, or push without instruction.

## Project tasks

Do not add or claim lifecycle tasks until the baseline import and managed-path manifest are complete. Once that gate is met, keep a small `Makefile` whose `check`, `install`, `status`, `reload`, `uninstall`, and optional `test` targets delegate to explicit scripts and act only on manifest paths.

## Related files

- [[README.md]]
- [[docs/interactions.md]]
- [[docs/dependencies.md]]
- [[docs/deployment.md]]
- [[docs/local-overrides.md]]
