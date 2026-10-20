## MODIFIED Requirements

### Requirement: Three-layer configuration

The system SHALL load configuration from three JSON sources merged in priority order: repository-level (highest), user-level, and distribution defaults (lowest). Deep merging SHALL preserve nested keys from lower-priority layers when not overridden. The merged configuration SHALL be loaded during KoalaVim's bootstrap, before the plugin manager resolves plugin specs, so that plugin specs can depend on configuration values.

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

#### Scenario: Configuration available to plugin specs
- **WHEN** a plugin spec module, `opts` function or `enabled` function is evaluated by the plugin manager
- **THEN** the merged configuration SHALL already be loaded and readable

### Requirement: Module loading system

The system SHALL load KoalaVim's options, keymaps and autocmd modules after LazyVim's corresponding defaults and before the user's corresponding config files. Other immediate-load modules SHALL run at startup, and deferred modules SHALL load after the plugin manager finishes. Module discovery SHALL NOT depend on external binaries.

#### Scenario: Deferred config loading
- **WHEN** the plugin manager reports startup complete
- **THEN** all deferred configuration modules SHALL be loaded and a user event SHALL fire to signal readiness

#### Scenario: User extension point
- **WHEN** the readiness event fires
- **THEN** user-provided deferred configuration modules SHALL also execute, allowing overrides of any distribution setting

#### Scenario: KoalaVim keymaps run after LazyVim's
- **WHEN** LazyVim finishes applying its default keymaps
- **THEN** KoalaVim's keymap modules SHALL run, followed by the user's `config/keymaps.lua`

#### Scenario: Module discovery without fd
- **WHEN** the `fd` binary is not installed
- **THEN** configuration modules SHALL still be discovered and loaded
