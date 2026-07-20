## Purpose

Editor enhancements improve everyday editing workflows: auto-saving, indentation detection, split zoom, whitespace management, file operations, find/replace, undo visualization, diagnostics browsing, and various quality-of-life features that make text editing more efficient.

## Requirements

### Requirement: Automatic file saving

The system SHALL automatically save files when leaving insert mode and on text changes. Saving SHALL be skipped for hex-mode buffers and non-normal editor modes.

#### Scenario: Auto-save on insert leave
- **WHEN** the user exits insert mode in a modified file buffer
- **THEN** the file SHALL be saved automatically

#### Scenario: Hex buffer excluded
- **WHEN** the current buffer is in hex view mode
- **THEN** auto-save SHALL not trigger

### Requirement: Indentation detection

The system SHALL auto-detect the indentation style (tabs vs. spaces) of each opened file. Tab sizes SHALL be clamped to configurable minimum and maximum bounds.

#### Scenario: Tab size clamping
- **WHEN** a file is opened with 8-space indentation and the maximum is configured as 4
- **THEN** the detected tab size SHALL be clamped to 4

#### Scenario: Editorconfig integration
- **WHEN** an `.editorconfig` file specifies an `indent_size` outside the configured bounds
- **THEN** the value SHALL be clamped to the configured min/max range

### Requirement: Split zoom

The system SHALL allow zooming any split into a near-full-screen floating window. Zoom SHALL auto-dismiss when focus leaves the floating window (unless entering a picker or popup).

#### Scenario: Zoom and auto-unzoom
- **WHEN** the user triggers zoom on a split
- **THEN** the split content SHALL appear in a floating window, and returning focus to another non-floating window SHALL close the float

### Requirement: TODO comment highlighting

The system SHALL highlight TODO, FIXME, HACK, and NOTE comments with distinct color-coded markers. Navigation between these markers SHALL be supported.

#### Scenario: Navigate between TODOs
- **WHEN** the user triggers next/previous TODO navigation
- **THEN** the cursor SHALL jump to the next/previous TODO-type comment in the buffer

### Requirement: URL and external resource opening

The system SHALL open URLs, file paths, and issue references (e.g., Jira tickets) under the cursor in the appropriate external application. Jira URL opening SHALL be configurable via the config system.

#### Scenario: Open URL under cursor
- **WHEN** the cursor is on a URL and the user triggers the open command
- **THEN** the URL SHALL open in the system's default browser

#### Scenario: Open Jira ticket
- **WHEN** a Jira base URL is configured and the cursor is on a ticket reference (e.g., `PROJ-123`)
- **THEN** the full Jira URL SHALL open in the browser

### Requirement: Trailing whitespace management

The system SHALL highlight trailing whitespace in real-time and trim trailing whitespace and blank lines at end of file on save. Trimming SHALL integrate cleanly with auto-save without conflicts.

#### Scenario: Trim on save
- **WHEN** a file is saved (manually or via auto-save)
- **THEN** trailing whitespace on all lines and trailing blank lines at the end of the file SHALL be removed

### Requirement: Cross-pane navigation

The system SHALL provide unified window navigation that works across editor splits and terminal multiplexer panes (tmux, wezterm). The same key bindings SHALL move focus seamlessly between editor and multiplexer boundaries.

#### Scenario: Navigate from editor to multiplexer pane
- **WHEN** the user presses the right-navigation key while in the rightmost editor split
- **THEN** focus SHALL move to the adjacent multiplexer pane to the right

### Requirement: Hex viewer

The system SHALL support toggling the current buffer between text and hexdump views.

#### Scenario: Toggle hex view
- **WHEN** the user toggles hex view on a text file
- **THEN** the buffer SHALL display a hexdump representation, and toggling again SHALL restore the text view

### Requirement: Elevated file access

The system SHALL support reading and writing files that require elevated permissions (sudo) without restarting the editor.

#### Scenario: Write protected file
- **WHEN** the user attempts to save a file they don't have write permission for
- **THEN** the system SHALL offer to write the file with elevated permissions

### Requirement: File operations

The system SHALL provide in-editor file operations: rename, trash, move, duplicate, copy path, and change permissions.

#### Scenario: Rename current file
- **WHEN** the user triggers the rename operation and provides a new name
- **THEN** the file SHALL be renamed on disk and the buffer SHALL update to reflect the new path

### Requirement: Undo history visualization

The system SHALL provide a visual tree browser for the full undo history, allowing non-linear undo exploration.

#### Scenario: Browse undo tree
- **WHEN** the user opens the undo tree
- **THEN** a visual tree showing all undo branches SHALL appear, and selecting a node SHALL restore that state

### Requirement: Interactive multi-pattern find and replace

The system SHALL support interactive multi-pattern search and replace with live preview. Both buffer-scoped and project-wide find/replace SHALL be available.

#### Scenario: Project-wide find and replace
- **WHEN** the user opens the project-wide find/replace UI, enters a search pattern and replacement
- **THEN** all matches across the project SHALL be shown with a preview of the replacement before applying

#### Scenario: Replace current word
- **WHEN** the user triggers find/replace with the cursor on a word
- **THEN** the find field SHALL be pre-populated with the word under the cursor

### Requirement: Diagnostics panel

The system SHALL provide a unified panel for viewing diagnostics, quickfix items, location list entries, LSP references, and TODO comments. Items SHALL be navigable.

#### Scenario: Navigate quickfix items
- **WHEN** the diagnostics panel is open showing quickfix items and the user triggers next-item
- **THEN** the cursor SHALL jump to the next item's location in the source file

### Requirement: Git permalink generation

The system SHALL generate permanent links to the current file and line on hosted Git platforms (GitHub, GitLab).

#### Scenario: Generate permalink
- **WHEN** the user triggers permalink generation on a line in a Git-tracked file
- **THEN** a permanent URL pointing to that specific line at the current commit SHA SHALL be copied to the clipboard

### Requirement: Dynamic scrolloff

The system SHALL set the scroll offset as a fraction of the window height (e.g., 10%) rather than a fixed line count, adapting to window size changes.

#### Scenario: Scrolloff adapts to window height
- **WHEN** the window is 40 lines tall with a 10% scrolloff
- **THEN** the effective scrolloff SHALL be 4 lines

### Requirement: Interesting word highlighting

The system SHALL allow the user to persistently highlight arbitrary words in the buffer using multiple distinct colors. Highlighting SHALL toggle on/off per word.

#### Scenario: Toggle highlight
- **WHEN** the user triggers highlight on a word that is not currently highlighted
- **THEN** all instances of that word SHALL be highlighted in a distinct color

### Requirement: Dim mode

The system SHALL support toggling a dimming effect on code outside the current scope (function, block) to help focus on relevant context.

#### Scenario: Toggle dim
- **WHEN** the user toggles dim mode
- **THEN** code outside the enclosing scope SHALL be visually dimmed

### Requirement: Nerd Font icon picker

The system SHALL provide a searchable picker for browsing and inserting Nerd Font icons, with recent-icon tracking.

#### Scenario: Insert icon from picker
- **WHEN** the user opens the icon picker and selects an icon
- **THEN** the icon character SHALL be inserted at the cursor position

### Requirement: Editable quickfix and registers

The system SHALL allow editing the quickfix list, location list, and registers as regular buffers. Changes SHALL be reflected back to the underlying data.

#### Scenario: Edit quickfix list
- **WHEN** the user opens the quickfix list in edit mode and removes an entry
- **THEN** the quickfix list SHALL update to exclude the removed entry

### Requirement: Markdown code fence editing

The system SHALL support opening fenced code blocks within markdown files in a separate floating window with full language-specific editing support (LSP, formatting).

#### Scenario: Edit code block in float
- **WHEN** the cursor is inside a markdown code fence and the user triggers code block editing
- **THEN** a floating window SHALL open with the code block's content, using the fenced language's LSP and formatting

### Requirement: Bracket repeat

The system SHALL support repeating the last bracket motion (`]x` / `[x`) by pressing `]` or `[` alone after the initial motion.

#### Scenario: Repeat last bracket motion
- **WHEN** the user presses `]f` to jump to the next function, then presses `]` again
- **THEN** the cursor SHALL jump to the next function after the current one

### Requirement: Visual marks

The system SHALL display visual indicators in the sign column for Vim marks and provide improved mark management bindings.

#### Scenario: Sign column marks
- **WHEN** the user sets a mark on a line
- **THEN** a visual indicator SHALL appear in the sign column on that line

### Requirement: Log file highlighting

The system SHALL provide syntax highlighting for `.log` files with color-coded severity levels.

#### Scenario: Log file opened
- **WHEN** a `.log` file is opened
- **THEN** log entries SHALL be syntax-highlighted with distinct colors for different severity levels
