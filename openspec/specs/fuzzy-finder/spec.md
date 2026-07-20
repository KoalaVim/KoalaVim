## Purpose

The fuzzy finder is the primary navigation interface: file search, full-text grep, buffer switching, LSP symbol navigation (definitions, references, implementations), git dirty files, spell/synonym lookup, and a unified picker framework that all other components route through.

## Requirements

### Requirement: File finder

The system SHALL provide a fuzzy file finder that searches across all project files, respecting gitignore and configurable ignore patterns. The finder SHALL support pre-populating from the current word, visual selection, or current filename.

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

All pickers SHALL support toggling between horizontal and vertical layouts, toggling the preview pane, navigating results with keyboard shortcuts, and sending results to the diagnostics panel.

#### Scenario: Toggle layout
- **WHEN** the user presses the layout-toggle key inside a picker
- **THEN** the picker SHALL switch between horizontal and vertical layout

#### Scenario: Toggle preview
- **WHEN** the user presses the preview-toggle key inside a picker
- **THEN** the preview pane SHALL show or hide

#### Scenario: Send to diagnostics panel
- **WHEN** the user presses the send-to-trouble key inside a picker
- **THEN** all current results SHALL be sent to the diagnostics panel for persistent navigation

### Requirement: Command history browser

The system SHALL provide a picker for browsing and re-executing previous command-line commands.

#### Scenario: Browse and execute
- **WHEN** the user opens the command history picker and selects a previous command
- **THEN** the command SHALL be executed

### Requirement: Spell and synonym lookup

The system SHALL provide pickers for spell correction suggestions and synonym lookup for the word under the cursor.

#### Scenario: Spell suggest
- **WHEN** the user triggers spell-suggest on a misspelled word
- **THEN** a picker SHALL show correction suggestions, and selecting one SHALL replace the word

#### Scenario: Synonym lookup
- **WHEN** the user triggers synonym lookup on a word
- **THEN** a picker SHALL show synonyms, and selecting one SHALL replace the word

### Requirement: Git dirty files picker

The system SHALL provide a picker showing all files with uncommitted changes (from `git status`), allowing quick navigation to modified files.

#### Scenario: Pick dirty file
- **WHEN** the user opens the dirty files picker and selects a file
- **THEN** the editor SHALL open that file

### Requirement: UI-select routing

The system SHALL route all `vim.ui.select()` calls through the fuzzy picker framework, providing consistent selection UX across all components.

#### Scenario: Component uses vim.ui.select
- **WHEN** any component calls `vim.ui.select()` with a list of options
- **THEN** the fuzzy picker SHALL handle the selection instead of the default prompt

### Requirement: Resume last search

The system SHALL support resuming the last fuzzy finder search with its previous query and results intact.

#### Scenario: Resume search
- **WHEN** the user triggers resume-search after having previously searched for files
- **THEN** the picker SHALL reopen with the previous query and results
