## Purpose

The autocompletion system provides intelligent code completion from multiple prioritized sources (LSP, paths, snippets, buffers, dictionary), snippet expansion and navigation, command-line completion, and specialized completions for git commits, debug sessions, and package managers.

## Requirements

### Requirement: Multi-source completion engine

The system SHALL provide autocompletion with multiple sources in priority order: LSP (highest), file paths, snippets, visible buffers, dictionary/word lookup, and calculator. Completion SHALL trigger automatically and be manually invocable.

#### Scenario: LSP completion prioritized
- **WHEN** both LSP and buffer sources offer completions for the same prefix
- **THEN** LSP completions SHALL appear above buffer completions in the menu

#### Scenario: Manual trigger
- **WHEN** the user presses the manual completion trigger key
- **THEN** the completion menu SHALL appear with all available completions

### Requirement: Smart LSP filtering

The system SHALL filter out redundant LSP keyword/text completions when the user has already typed the matching content. LSP completion item kinds SHALL be custom-priority-ordered for relevance.

#### Scenario: Filter redundant text completion
- **WHEN** the user has typed `function` and LSP offers `function` as a text completion
- **THEN** that redundant completion SHALL be filtered out

### Requirement: Snippet support

The system SHALL support TextMate/UltiSnips-compatible snippets with tab-stop navigation. Tab and shift-tab SHALL navigate between snippet placeholders when a snippet is active; otherwise, they SHALL select completion menu items.

#### Scenario: Expand and navigate snippet
- **WHEN** the user selects a snippet completion and presses tab
- **THEN** the snippet SHALL expand and the cursor SHALL jump to the first placeholder; subsequent tab presses SHALL move to the next placeholder

#### Scenario: Tab without active snippet
- **WHEN** the completion menu is visible and no snippet is active
- **THEN** tab SHALL select the next item in the completion menu

### Requirement: Command-line completion

The system SHALL provide autocompletion in the `/` search command line (from visible buffer content) and the `:` command line (from paths and command names).

#### Scenario: Search completion
- **WHEN** the user types in the `/` search prompt
- **THEN** completions from visible buffer content SHALL be offered

#### Scenario: Command completion
- **WHEN** the user types in the `:` command prompt
- **THEN** command names and file paths SHALL be offered as completions

### Requirement: Completion item icons

The system SHALL display icons representing the kind of each completion item (function, variable, class, snippet, etc.) for quick visual identification.

#### Scenario: Function icon
- **WHEN** a completion item is an LSP function
- **THEN** a function icon SHALL appear next to the item in the menu

### Requirement: Auto-pair on completion

The system SHALL automatically complete matching pairs (brackets, quotes) when a completion item is confirmed, if the completion introduces an opening character.

#### Scenario: Confirm function completion
- **WHEN** the user confirms a function-call completion
- **THEN** if the completion includes `(`, the matching `)` SHALL be auto-inserted

### Requirement: Explicit selection confirmation

The system SHALL only confirm a completion when the user has explicitly selected an item. Pressing enter without selecting SHALL insert a newline, not confirm the first item.

#### Scenario: Enter without selection
- **WHEN** the completion menu is visible but no item is highlighted and the user presses enter
- **THEN** a newline SHALL be inserted and the menu SHALL close

### Requirement: Specialized completion sources

The system SHALL provide context-specific completion sources: GitHub-aware completions in git commit messages, debug REPL completions during debug sessions, and crate name/version completions in Rust dependency files.

#### Scenario: Git commit completion
- **WHEN** the user is composing a git commit message
- **THEN** GitHub issue numbers, usernames, and emoji codes SHALL be offered as completions

#### Scenario: Cargo.toml crate completion
- **WHEN** the user is editing a Cargo.toml file and typing a dependency name
- **THEN** crate names and versions from the registry SHALL be offered as completions

#### Scenario: Debug REPL completion
- **WHEN** the user is typing in the debug REPL
- **THEN** variable names and expressions from the debug context SHALL be offered as completions

### Requirement: Completion documentation scrolling

The system SHALL support scrolling through the documentation preview of a selected completion item when the documentation is longer than the popup.

#### Scenario: Scroll documentation
- **WHEN** a completion item is selected and its documentation exceeds the popup height
- **THEN** the user SHALL be able to scroll up and down within the documentation preview

### Requirement: Language-specific snippets

The system SHALL ship with curated snippet collections for common languages (C/C++, Go, Lua, Python) covering frequent patterns like struct definitions, error handling, main functions, and interface checks.

#### Scenario: Go snippet expansion
- **WHEN** the user triggers a Go snippet for struct definition
- **THEN** a struct template SHALL expand with placeholders for the struct name and fields
