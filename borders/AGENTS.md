---
author: T. G. Kelemen
title: coding project - borders
comment: project instructions;
subject: window border appearance
description: Local instructions for borders.
keywords: macOS; borders; window management;
organization: dialectStudio, LLC
copyright: Coding project © 2026 dialectStudio, LLC; underlying source text and third-party materials remain the property of their respective rights holders.
---

# Borders

Follow the root `AGENTS.md`. This directory owns executable `bordersrc` and borders-only helpers. Keep border styling and focus behavior here; do not add yabai, skhd, or SketchyBar coupling unless its contract is first recorded in `docs/interactions.md`.

Check `bordersrc` with `/bin/zsh -n borders/bordersrc`. Preserve its executable mode, use the Homebrew service reload documented in `docs/deployment.md`, and visually verify focused, unfocused, and excluded windows after deployment.
