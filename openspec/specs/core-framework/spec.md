## Purpose

The core framework bootstraps KoalaVim: loading configuration from a three-layer JSON merge, persisting runtime state, supporting startup modes for specialized workflows, and providing the module loading system that all other components build on.

## Requirements

### Requirement: Three-layer configuration

The system SHALL load configuration from three JSON sources merged in priority order: repository-level (highest), user-level, and distribution defaults (lowest). Deep merging SHALL preserve nested keys from lower-priority layers when not overridden.

#### Scenario: Repository config overrides user config
- **WHEN** a user has `"editor.indent.tab_size.min": 4` in their user config and the repository config sets `"editor.indent.tab_size.min": 2`
- **THEN** the effective value for `editor.indent.tab_size.min` SHALL be `2`

#### Scenario: User config fills in unset keys
- **WHEN** the repository config does not set `ui.statusline.icons_only` but the user config sets it to `true`
- **THEN** the effective value SHALL be `true`

#### Scenario: Default config provides baseline
- **WHEN** neither user nor repository config sets a key that exists in the distribution defaults
- **THEN** the default value SHALL be used

#### Scenario: Repository config resolves across git worktrees
- **WHEN** the editor is opened inside a git worktree and no `.kvim.conf` exists in the worktree root
- **THEN** the system SHALL fall back to the `.kvim.conf` in the main worktree root

### Requirement: Configuration schema validation

The system SHALL provide a JSON schema describing all configuration keys, their types, and descriptions. Editors with JSON schema support SHALL offer autocompletion and validation for config files.

#### Scenario: Schema registered for config files
- **WHEN** a JSON language server is active and the user opens a `.kvim.conf` file
- **THEN** the language server SHALL provide completion and validation using the distribution's schema

### Requirement: Persistent state

The system SHALL persist runtime state as JSON in the user's data directory. State SHALL survive editor restarts and be available to all components.

#### Scenario: State survives restart
- **WHEN** a component writes to the state store and the editor is closed and reopened
- **THEN** the previously written state values SHALL be available

### Requirement: Startup modes

The system SHALL support launching in specialized modes via environment variables. Each mode configures the editor for a specific workflow on startup.

#### Scenario: Git mode
- **WHEN** the editor is launched with the git startup mode
- **THEN** the git log graph and git status views SHALL open automatically

#### Scenario: AI mode
- **WHEN** the editor is launched with the AI startup mode and an optional tool name
- **THEN** the AI sidecar panel SHALL open with the specified tool and auto-zoom to fill the screen

#### Scenario: Git diff mode
- **WHEN** the editor is launched with the git diff startup mode
- **THEN** the diff viewer SHALL open and all other tabs SHALL close

### Requirement: Module loading system

The system SHALL recursively load configuration modules from designated directories. Immediate-load modules SHALL run at startup; deferred modules SHALL load after the plugin manager finishes.

#### Scenario: Deferred config loading
- **WHEN** the plugin manager reports startup complete
- **THEN** all deferred configuration modules SHALL be loaded and a user event SHALL fire to signal readiness

#### Scenario: User extension point
- **WHEN** the readiness event fires
- **THEN** user-provided deferred configuration modules SHALL also execute, allowing overrides of any distribution setting

### Requirement: Debug logging

The system SHALL provide a global debug logging function. When debug mode is enabled via an environment variable, debug output SHALL be written to both the notification system and a log file. When disabled, debug calls SHALL be no-ops with no performance impact.

#### Scenario: Debug enabled
- **WHEN** the debug environment variable is set
- **THEN** debug calls SHALL write messages (including inspected tables) to the notification system and the specified log file

#### Scenario: Debug disabled
- **WHEN** the debug environment variable is not set
- **THEN** the debug function SHALL be replaced with a no-op

### Requirement: Global registries

The system SHALL initialize shared global registries at startup for LSP servers, linters/formatters, modal sub-modes, formatters, help bindings, and ghost filetypes. Components SHALL register into these tables to participate in cross-cutting features.

#### Scenario: LSP server registration
- **WHEN** a language support module loads
- **THEN** it SHALL register its server configuration into the global LSP servers registry

#### Scenario: Ghost filetype registration
- **WHEN** a component declares a filetype as "ghost" (non-user-content buffer)
- **THEN** that filetype SHALL be excluded from session restoration and buffer-counting logic
