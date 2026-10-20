## ADDED Requirements

### Requirement: LazyVim spec layering

KoalaVim's plugin spec SHALL be layered on top of LazyVim in this import order: `lazyvim.plugins` first, then the LazyVim extras KoalaVim requires, then `KoalaVim.plugins` (including its sub-imports), and the user's `plugins` last. KoalaVim specs SHALL override LazyVim specs for the same plugin, and user specs SHALL override both.

#### Scenario: KoalaVim overrides a LazyVim plugin option
- **WHEN** LazyVim and KoalaVim both configure the same plugin's `opts`
- **THEN** KoalaVim's values SHALL take precedence in the merged opts

#### Scenario: User overrides KoalaVim
- **WHEN** a user's `lua/plugins/*.lua` configures a plugin that KoalaVim also configures
- **THEN** the user's values SHALL take precedence

#### Scenario: No import-order warning
- **WHEN** the editor starts with the standard KoalaVim bootstrap
- **THEN** LazyVim SHALL NOT emit its "order of your lazy.nvim imports is incorrect" warning

### Requirement: Pinned LazyVim dependency

LazyVim SHALL be pinned to a specific commit in KoalaVim's deterministic `lazy-lock.json`, like every other plugin. LazyVim upgrades SHALL ship only with KoalaVim releases.

#### Scenario: Restoring the lockfile pins LazyVim
- **WHEN** a user restores plugins from KoalaVim's lockfile
- **THEN** LazyVim SHALL be checked out at the commit recorded in the lockfile

### Requirement: Required and user-selected extras

KoalaVim SHALL import the LazyVim extras it depends on from its own spec. Users SHALL be able to enable additional extras with `:LazyExtras`, persisted in `lazyvim.json` in their config directory.

#### Scenario: KoalaVim-required extra is always active
- **WHEN** the editor starts with a fresh config that has no `lazyvim.json`
- **THEN** every extra KoalaVim depends on SHALL be loaded

#### Scenario: User enables an extra
- **WHEN** the user enables an extra in `:LazyExtras` and restarts
- **THEN** that extra SHALL be loaded, and KoalaVim's specs SHALL still be applied after it

### Requirement: Layered options, keymaps and autocmds

Options, keymaps and autocmds SHALL be applied in this order: LazyVim's defaults, then KoalaVim's, then the user's `config/options.lua`, `config/keymaps.lua` and `config/autocmds.lua`. KoalaVim's layer SHALL run on LazyVim's `LazyVimOptionsDefaults`, `LazyVimKeymapsDefaults` and `LazyVimAutocmdsDefaults` events. Each user config file SHALL be loaded exactly once.

#### Scenario: KoalaVim option overrides LazyVim default
- **WHEN** LazyVim sets an option default and KoalaVim sets a different value for it
- **THEN** KoalaVim's value SHALL be in effect after startup

#### Scenario: User option overrides KoalaVim
- **WHEN** the user's `config/options.lua` sets an option that KoalaVim also sets
- **THEN** the user's value SHALL be in effect after startup

#### Scenario: User config loaded once
- **WHEN** the editor starts with a user `config/keymaps.lua`
- **THEN** that file SHALL execute exactly once

### Requirement: LazyVim-managed treesitter with KoalaVim additions

Treesitter parsers, highlighting, folding and indentation SHALL be managed by LazyVim's treesitter setup. KoalaVim SHALL add its own parsers, its treesitter plugins (end-wise, enhanced matching, JSON path, sticky context) and its custom language registrations.

#### Scenario: KoalaVim parser added to install list
- **WHEN** KoalaVim requires a parser that LazyVim does not install by default
- **THEN** that parser SHALL be installed along with LazyVim's list

#### Scenario: AI prompt buffers highlighted as markdown
- **WHEN** a `sidekick_koala_prompt` buffer is opened
- **THEN** it SHALL be highlighted with the markdown treesitter parser

### Requirement: Large-file and fast-start protections

The system SHALL disable expensive features (treesitter, LSP, syntax-heavy plugins) for very large files, and SHALL render files opened from the command line before the full plugin set loads.

#### Scenario: Open a very large file
- **WHEN** the user opens a file above the large-file threshold
- **THEN** the file SHALL open with expensive features disabled

### Requirement: LazyVim news

The system SHALL show LazyVim's NEWS on updates in which it changed.

#### Scenario: LazyVim news changed
- **WHEN** the pinned LazyVim version is upgraded and its NEWS file changed
- **THEN** the news SHALL be displayed on the next startup
