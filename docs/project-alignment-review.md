# Project alignment review

Date: 2026-09-26

Status: historical pre-import review. Its recommendations were used to prepare
the initial managed repository; current operational truth lives in `README.md`,
`scripts/managed-paths`, and the focused documents under `docs/`. Findings below
describe the repository at review time and are retained as migration history.

## Objective

Make this repository the source of truth for one local macOS window-management
setup composed of borders, SketchyBar, skhd, and yabai, while preserving clear
ownership, reviewable cross-application contracts, local-only settings, and a
safe deployment path.

## Scope

This review covers:

- `AGENTS.md`
- `borders/AGENTS.md`
- `sketchybar/AGENTS.md`
- `skhd/AGENTS.md`
- `yabai/AGENTS.md`
- the current repository structure and Git state
- `README.md`, `docs/interactions.md`, and `docs/notes.md`
- a read-only inventory of the installed files under
  `$HOME/.config/{borders,sketchybar,skhd,yabai}`

Secret values were not inspected.

## Overall assessment

The five `AGENTS.md` files agree on the most important architectural boundary:
yabai owns window and space policy, skhd owns bindings, SketchyBar owns display
and interaction, and borders owns border appearance. The root file also gives
sound safety rules for preserving local state and deploying incrementally.

The project is not yet able to meet its stated source-of-truth objective. It is
in a partial-import state, has no committed baseline or `.gitignore`, does not
define exactly which live paths it will manage, and has no deployment tasks.
The application instructions need a few precise additions rather than a major
rewrite.

## Findings

### P0: Establish a safe source-of-truth baseline

1. **The repository is incomplete.** The installed borders and SketchyBar
   configurations are absent. The current installed yabai configuration and
   helpers are absent; the repository contains only two historical `zz_*`
   yabai files. `skhd/skhdrc` is the only current application configuration and
   is byte-identical to the installed file at the review date.

2. **The repository has no commit and no `.gitignore`.** All files are
   currently untracked. `.DS_Store`, `.session_ids`, two
   `.sublime-workspace` files, backup/original files, and duplicate Sublime
   project files are present at the root. This conflicts with `AGENTS.md:23-24`
   and `AGENTS.md:44`, and creates a high risk of committing generated or
   machine-specific state.

3. **The managed installation boundary is undefined.** `AGENTS.md:40` correctly
   prohibits replacing all four live trees blindly, and `README.md:37` allows
   either directory or file links, but neither file identifies the paths this
   project owns. The live SketchyBar and yabai trees contain a mixture of source,
   local overlays, runtime state, and backups, so whole-directory links are not
   currently safe.

4. **Cross-application contracts are undocumented.**
   `docs/interactions.md` is empty even though skhd calls yabai, yabai emits
   events to SketchyBar, SketchyBar queries and commands yabai, and skhd exposes
   reload actions for all four applications. This conflicts with
   `AGENTS.md:28-32` and `AGENTS.md:42`.

### P1: Make the instructions operationally unambiguous

5. **Source, local configuration, secrets, and runtime state are not clearly
   separated.** The instructions prohibit committing credentials, but do not
   define local-overlay filenames, example-file conventions, expected file
   permissions, or runtime-state locations. These rules are especially needed
   for SketchyBar weather/Plex data and yabai display topology.

6. **The project-task layout is incomplete.** `AGENTS.md:46-48` requires a
   `Makefile` to delegate to scripts, but no directory owns repository lifecycle
   scripts. `bin/` is already reserved for commands called by multiple runtime
   configurations (`AGENTS.md:32`), so install/check/reload scripts should not
   be placed there.

7. **Canonical workspace and event definitions are not required.** The live
   configuration currently has competing `Development` and `dev` labels, and
   SketchyBar subscribes to custom events whose registration or ordering is
   incomplete. The root and app instructions require documentation, but should
   additionally prohibit duplicate definitions and require custom events to be
   registered before consumers subscribe.

8. **Dependencies and permissions are not inventoried.** The live setup uses
   more than the four primary programs, including `jq`, Homebrew Bash, curl,
   AppleScript, macOS network tools, optional SketchyBar helpers, fonts, and
   user commands called by skhd. Accessibility, Automation, database access,
   and the existing yabai scripting-addition setup also affect operation.

### P2: Remove ambiguity and historical clutter

9. **Naming is inconsistent.** `README.md:9` proposes
   `window-management.sublime-project`, while three differently named project
   candidates and two workspaces are present. Only one portable project file
   should remain.

10. **Historical files occupy canonical app directories.** Prefixes such as
    `zz_`, `original`, and `before-*` do not establish whether a file is active,
    dormant, or archival. Historical snapshots should be recovered from Git
    history rather than retained beside deployable files.

11. **The documentation roles are unclear.** `docs/notes.md` mixes feature ideas
    with active defects. A small backlog with status and acceptance criteria is
    more useful, while stable operational facts should live in focused reference
    documents.

## Recommended `AGENTS.md` revisions

Keep the instruction files concise. Put stable rules in `AGENTS.md`; put
inventories, contracts, procedures, and change history in `docs/`.

### Root `AGENTS.md`

Retain the ownership boundaries and safety rules. Add or clarify the following:

- Define the repository layout as a mirror of managed paths relative to `$HOME/.config/<app>/`, not as permission to link an entire live directory.
- Require one explicit managed-path manifest used by install, status, and uninstall operations.
- Define four file classes: managed source, local overlay, secret, and generated runtime state. Only managed source and sanitized `.example` files belong in Git.
- Reserve `scripts/` for repository lifecycle commands. Keep `bin/` exclusively for commands invoked by two or more runtime app configurations, and omit it until such a command exists.
- Require a single canonical workspace model and prohibit ad hoc relabeling by consumers or late configuration blocks.
- Require custom event registration before subscription. Record producer, event name, payload/environment, timing assumptions, and all consumers in `docs/interactions.md`.
- Clarify that preserving an already configured yabai scripting addition is allowed, while installing or changing its sudoers/system-protection setup still requires an explicit task.
- Require exact executable-mode preservation for entry points and executable plugins/helpers.
- Point to `docs/dependencies.md`, `docs/deployment.md`, and `docs/local-overrides.md` as the canonical operational references.
- Change the project-task wording from “once the live configs have been imported” to an explicit phase gate: do not add or claim `Makefile` tasks until the baseline import and managed-path manifest are complete.

### `borders/AGENTS.md`

The current boundary is appropriate. Add:

- The full owned subtree is `bordersrc` plus borders-only helpers, if any.
- Whether `bordersrc` is executed or sourced, its required mode, and its actual validation command.
- The current service/reload command by reference to `docs/deployment.md` rather than an ambiguous instruction to preserve an undocumented method.
- A rule that borders remains free of yabai/SketchyBar coupling unless a real contract is first added to `docs/interactions.md`.

### `sketchybar/AGENTS.md`

The display/interaction ownership is appropriate. Add:

- Ownership of `sketchybarrc`, shared style/icon files, `items/`, `plugins/`, and sanitized examples under `config/`.
- A distinction between sourced item/config files and executable plugins so mode checks are accurate.
- One central custom-event registration location, loaded before any item that subscribes to those events.
- A requirement that each item identify its event subscriptions, script, update frequency, and click action in `docs/interactions.md`.
- Explicit exclusions for credentials, logs, caches, temporary artwork/data, archives, backups, and generated `.dat` files.
- A requirement that optional dependencies fail visibly but do not break the rest of the bar.

### `skhd/AGENTS.md`

The binding ownership and DSL warning are appropriate. Add:

- Direct one-step yabai commands are allowed, but branching, querying followed by policy decisions, or multi-step layout behavior belongs in a yabai-owned helper or a genuinely shared command.
- External commands not owned by this repository must be listed in `docs/dependencies.md`; missing optional commands should not make unrelated bindings fail.
- Keep a canonical hotkey inventory in `docs/hotkeys.md`, including modifier policy, conflicts, destination command, and owning app.
- Validate duplicate active bindings and malformed annotation metadata without treating `skhdrc` itself as a shell program.
- Reference the documented reload procedure rather than relying only on a reload hotkey inside the file being reloaded.

The inline layout branch at `skhd/skhdrc:217` is an example of policy that should move to a yabai-owned script after the baseline import. Calls such as `yabai -m window --focus west` can remain direct.

### `yabai/AGENTS.md`

The policy ownership is appropriate. Add:

- Ownership of `yabairc`, `scripts/`, `maintenance/`, the focus helper, and the portable topology logic.
- Require all space labels, order, default layouts, and default applications to derive from one canonical model documented in `docs/workspaces.md`.
- Treat physical display identifiers and machine topology overrides as a local-only file, with a sanitized tracked `.example`.
- Require labeled rules and signals to be idempotent, and require signal environment variables and downstream event payloads to be documented.
- Preserve the current scripting-addition behavior during import, but do not provision or modify sudoers as part of routine checks or installation.
- Require non-mutating syntax/static checks before any live rule, space, or signal verification.

## Recommended folder structure

```text
home-window-management/
├── .gitignore
├── AGENTS.md
├── README.md
├── Makefile                         # only after lifecycle tasks exist
├── home-window-management.sublime-project
├── scripts/                         # repository lifecycle, not runtime logic
│   ├── managed-paths.zsh
│   ├── check.zsh
│   ├── install.zsh
│   ├── status.zsh
│   ├── reload.zsh
│   └── uninstall.zsh
├── bin/                             # omit until a multi-app command exists
├── borders/
│   ├── AGENTS.md
│   └── bordersrc
├── sketchybar/
│   ├── AGENTS.md
│   ├── sketchybarrc
│   ├── colors.sh
│   ├── globalstyles.sh
│   ├── icons.sh
│   ├── config/
│   │   └── *.example
│   ├── items/
│   └── plugins/
├── skhd/
│   ├── AGENTS.md
│   └── skhdrc
├── yabai/
│   ├── AGENTS.md
│   ├── yabairc
│   ├── focus-default-app.zsh
│   ├── topology.zsh
│   ├── topology.local.zsh.example
│   ├── maintenance/
│   └── scripts/
├── docs/
│   ├── project-alignment-review.md
│   ├── interactions.md
│   ├── dependencies.md
│   ├── deployment.md
│   ├── hotkeys.md
│   ├── local-overrides.md
│   ├── workspaces.md
│   └── backlog.md
└── tests/                           # omit until useful isolated tests exist
```

Do not add empty directories merely to match this diagram. Add `scripts/`,
`bin/`, and `tests/` only when they contain implemented behavior.

## Import classification

Use this classification before copying the live trees.

| Class | Examples | Repository treatment |
| --- | --- | --- |
| Managed source | app entry points, active items/plugins, yabai helpers | Import at native relative paths and preserve modes |
| Local overlay | physical display topology, weather location/provider settings | Track a sanitized `.example`; leave real file unowned |
| Secret | API tokens, Plex credentials | Keep outside Git; document location and restrictive permissions |
| Runtime/generated | logs, caches, `.dat`, temporary artwork, lock files | Keep outside Git and ignore |
| Historical | `zz_*`, `*original*`, `*before-*`, backups, archives | Exclude; use Git history after baseline import |

At the review date, notable exclusions include root `.DS_Store`, `.session_ids`,
all `.sublime-workspace` files, live SketchyBar logs/data/archives/backups, and
live yabai historical snapshots. The original Sublime project containing
absolute `$HOME/.config` paths should also be excluded.

## Documentation alignment

### `docs/interactions.md`

Make this the contract registry, not a prose overview. Use tables for:

- yabai signal to SketchyBar event flows
- SketchyBar queries and click commands sent to yabai
- skhd commands sent to yabai and service controls
- environment variables such as `YABAI_SPACE_INDEX`
- native SketchyBar events and custom event registration order

Each record should include producer, consumer, command/event, payload or
environment, timing assumptions, failure behavior, and verification step.

### Additional documents

- `docs/dependencies.md`: required/optional binaries, exact paths, fonts,
  external user commands, and macOS permissions.
- `docs/deployment.md`: managed paths, backup/refusal behavior, install, status,
  reload order, uninstall, rollback, and live smoke checks.
- `docs/hotkeys.md`: binding inventory and modifier policy.
- `docs/local-overrides.md`: local filenames, `.example` conventions, secret
  locations and modes, and runtime-state locations.
- `docs/workspaces.md`: canonical labels, indices, layouts, application rules,
  and display/topology assumptions.
- `docs/backlog.md`: migrate actionable entries from `docs/notes.md`; give each
  an owner, status, expected behavior, and verification criterion.

## Live integration issues discovered during review

These are not instruction-file changes, but they block the project objective
and should be preserved in the baseline import before being fixed in separate,
reviewable changes:

1. The live yabai configuration defines the semantic label `Development` and
   later relabels the same space to `dev`; live SketchyBar code expects
   `Development`.
2. yabai emits the custom SketchyBar event `space_windows_change`, while no
   live file registers that custom event before subscription.
3. `network_location_changed` is registered after some consumers subscribe.
4. The live SketchyBar entry point sources a missing `items/dndindicator.sh`.
5. A continued command in the live `items/yabai.sh` is interrupted by a comment,
   leaving later subscriptions malformed.
6. Several active helper paths differ from the installed filenames or Homebrew
   prefix, including the brew click helper and `icalBuddy`.
7. The live yabai topology reconciliation script is not called from the active
   entry point, so it is currently dormant.
8. The live configuration depends on external user commands and optional tools
   that are not documented.

Import first without combining cleanup or behavior changes. Once an exact
baseline is committed, fix each active defect at its owning application and
update `docs/interactions.md` in the same change.

## Recommended sequence

1. Add a minimal `.gitignore`; remove generated, machine-specific, duplicate,
   and historical root artifacts from the intended tracked set.
2. Select one portable Sublime project filename and update `README.md` to match.
3. Inventory every live file by the five import classes above; record modes and
   dependencies without copying secrets.
4. Import the four active configurations unchanged at native relative paths and
   preserve executable modes.
5. Create the managed-path manifest and populate the stable documentation.
6. Commit the baseline before fixing behavior, rearranging files, or formatting.
7. Correct active cross-app defects in small owner-scoped changes, updating
   interaction contracts and smoke checks with each change.
8. Implement idempotent lifecycle scripts and expose them through the required
   `Makefile` targets.
9. Deploy only the manifest paths, verify links and modes, reload in the order
   yabai, skhd, SketchyBar, borders, and perform one live integration check.

## Acceptance criteria

The alignment is complete when:

- Git contains one clean baseline of all active, non-secret managed source.
- `git status` is not polluted by editor, macOS, runtime, or local-overlay files.
- Every deployed path is present in one ownership manifest.
- Install and uninstall leave unowned files in each live config tree untouched.
- `make check`, `make install`, `make status`, `make reload`, and
  `make uninstall` exist and accurately reflect implemented behavior.
- Every cross-app event and command is represented in
  `docs/interactions.md`.
- Workspace labels have one canonical definition shared by callers and
  consumers.
- Required dependencies, permissions, local overrides, secrets, and runtime
  state are documented without exposing secret values.
- Syntax/static checks preserve app-specific semantics and executable modes.
- A clean install can reload all four applications and pass the documented
  shortcut, space, bar-update, and border-focus smoke checks.
