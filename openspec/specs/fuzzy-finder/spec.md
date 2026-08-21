## Purpose

The fuzzy finder is the primary navigation interface: file search, full-text grep, buffer switching, LSP symbol navigation (definitions, references, implementations), git dirty files, spell/synonym lookup, and a unified picker framework that all other components route through.

## Requirements

### Requirement: File finder

The system SHALL provide a fuzzy file finder that searches across all project files, respecting gitignore and configurable ignore patterns. Results SHALL be ranked by frecency (frequency + recency of access). The finder SHALL support pre-populating from the current word, visual selection, or current filename.

#### Scenario: Find file with ignore patterns
- **WHEN** the user opens the file finder in a project with configured additional ignore patterns
- **THEN** files matching those patterns SHALL be excluded from results

#### Scenario: Pre-populate from current word
- **WHEN** the user triggers the find-current-file variant
- **THEN** the search field SHALL be pre-populated with the word under the cursor

#### Scenario: Find related files by name
- **WHEN** the user triggers find-by-current-filename while editing `user.lua`
- **THEN** the search SHALL be pre-populated with `user` to quickly find related files (e.g., `user_test.lua`, `user_spec.lua`)

### Requirement: Live text search (grep)

The system SHALL provide live full-text search across the project using ripgrep. The search SHALL support raw ripgrep arguments for file type filtering (`-t`/`-T`) and glob patterns (`-g`). Directory-scoped grep and operator-mode grep (motion-based text selection) SHALL be available.

#### Scenario: Search with file type filter
- **WHEN** the user types a search query followed by `-t lua`
- **THEN** only `.lua` files SHALL be searched

#### Scenario: Directory-scoped grep
- **WHEN** the user triggers grep scoped to the current file's directory
- **THEN** only files within that directory (recursively) SHALL be searched

#### Scenario: Operator-mode grep
- **WHEN** the user triggers grep in operator mode and applies a motion (e.g., `iw` for inner word)
- **THEN** the selected text SHALL be used as the grep query

### Requirement: Buffer browser

The system SHALL provide a fuzzy picker for switching between open buffers, showing buffer names, paths, and indicators for modified state.

#### Scenario: Switch buffer
- **WHEN** the user opens the buffer browser and selects a buffer
- **THEN** the editor SHALL switch to that buffer in the current window

### Requirement: LSP navigation via picker

The system SHALL provide fuzzy pickers for all LSP navigation targets: definitions, references (excluding declarations), implementations, type definitions, document symbols, workspace symbols, and diagnostics. Each navigation target SHALL have variants for opening in the current window, a vertical split, or a horizontal split.

#### Scenario: Go to definition
- **WHEN** the user triggers go-to-definition on a symbol
- **THEN** the cursor SHALL jump to the symbol's definition (or show a picker if multiple definitions exist)

#### Scenario: Go to definition in vertical split
- **WHEN** the user triggers go-to-definition-in-vsplit on a symbol
- **THEN** a vertical split SHALL be created (or reused if one exists) and the definition SHALL open there

#### Scenario: Go to references excluding declarations
- **WHEN** the user triggers go-to-references on a symbol
- **THEN** a picker SHALL show all references to that symbol, excluding the declaration itself

#### Scenario: Document symbols
- **WHEN** the user triggers document symbols
- **THEN** a compact picker SHALL show all symbols in the current document with cursor-relative ordering

#### Scenario: Non-LSP fallback
- **WHEN** the user triggers go-to-definition on a keyword that has no LSP definition
- **THEN** the system SHALL fall back to man page or help documentation lookup

### Requirement: Picker layout and interaction

All pickers SHALL support toggling the preview pane, navigating results with keyboard shortcuts, and sending results to the diagnostics panel.

The picker framework SHALL define a single project-wide default layout, and individual picker sources SHALL be able to override it with a layout appropriate to their content. A source's layout override SHALL take effect without requiring the override to restate the full window structure. Result ordering SHALL follow the layout's search field position rather than being fixed globally.

#### Scenario: Toggle preview
- **WHEN** the user presses the preview-toggle key inside a picker
- **THEN** the preview pane SHALL show or hide

#### Scenario: Send to diagnostics panel
- **WHEN** the user presses the send-to-trouble key inside a picker
- **THEN** all current results SHALL be sent to the diagnostics panel for persistent navigation

#### Scenario: Default layout applies to content pickers
- **WHEN** the user opens a picker that does not declare its own layout (file finder, grep, LSP navigation, diagnostics)
- **THEN** the picker SHALL use the project default layout: a large window with the results list above the search field and a preview pane alongside

#### Scenario: Source-specific layout override takes effect
- **WHEN** a picker source declares a layout override, such as a compact popup for short option lists
- **THEN** the picker SHALL render with that override rather than the project default layout

#### Scenario: Result ordering follows the search field position
- **WHEN** a picker's layout places the search field below the results list
- **THEN** results SHALL be ordered bottom-up so the best match sits nearest the search field
- **WHEN** a picker's layout places the search field above the results list
- **THEN** results SHALL be ordered top-down, again nearest the search field

### Requirement: Command history browser

The system SHALL provide a picker for browsing and re-executing previous command-line commands.

#### Scenario: Browse and execute
- **WHEN** the user opens the command history picker and selects a previous command
- **THEN** the command SHALL be executed

### Requirement: Spell correction

The system SHALL provide a picker for spell correction suggestions for the word under the cursor.

#### Scenario: Spell suggest
- **WHEN** the user triggers spell-suggest on a misspelled word
- **THEN** a compact picker SHALL show correction suggestions near the cursor, and selecting one SHALL replace the word

### Requirement: Git dirty files picker

The system SHALL provide a picker showing all files with uncommitted changes (from `git status`), allowing quick navigation to modified files.

#### Scenario: Pick dirty file
- **WHEN** the user opens the dirty files picker and selects a file
- **THEN** the editor SHALL open that file

### Requirement: UI-select routing

The system SHALL route all `vim.ui.select()` calls through the fuzzy picker framework, providing consistent selection UX across all components.

Selection prompts SHALL render as a compact picker sized to the number of options, with no preview pane. The system SHALL NOT display previewer output for selection items, since the items being selected are arbitrary values rather than file locations.

#### Scenario: Component uses vim.ui.select
- **WHEN** any component calls `vim.ui.select()` with a list of options
- **THEN** the fuzzy picker SHALL handle the selection instead of the default prompt

#### Scenario: Selection prompt is compact and preview-less
- **WHEN** a component calls `vim.ui.select()` with a small list of options
- **THEN** the picker SHALL open as a compact popup sized to the option count
- **AND** no preview pane SHALL be shown

#### Scenario: No internal data leaks into the prompt
- **WHEN** the selected option is a table carrying internal state, such as an AI CLI tool entry with its session and process details
- **THEN** the picker SHALL show only the formatted option label
- **AND** SHALL NOT render a dump of the option's underlying data

### Requirement: Resume last search

The system SHALL support resuming the last fuzzy finder search with its previous query and results intact.

#### Scenario: Resume search
- **WHEN** the user triggers resume-search after having previously searched for files
- **THEN** the picker SHALL reopen with the previous query and results
