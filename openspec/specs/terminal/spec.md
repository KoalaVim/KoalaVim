## Purpose

The terminal system provides integrated terminal management within the editor: toggling all terminals, multi-instance support, smart working directory selection, terminal splitting, and vim-style prompt editing.

## Requirements

### Requirement: Terminal toggle

The system SHALL provide a single key to toggle all terminal windows on and off. If no terminals exist when toggling on, a new terminal SHALL be created.

#### Scenario: Toggle on with no terminals
- **WHEN** the user presses the terminal toggle key and no terminals exist
- **THEN** a new terminal SHALL be created and opened

#### Scenario: Toggle off
- **WHEN** terminals are visible and the user presses the terminal toggle key
- **THEN** all terminal windows SHALL be hidden (but remain running in the background)

#### Scenario: Toggle on with existing terminals
- **WHEN** terminals exist but are hidden and the user presses the terminal toggle key
- **THEN** all previously hidden terminals SHALL reappear

### Requirement: Multi-instance terminals

The system SHALL support multiple terminal instances with auto-incrementing identifiers. Each new terminal SHALL get a unique ID.

#### Scenario: Create additional terminal
- **WHEN** the user creates a new terminal while one already exists
- **THEN** the new terminal SHALL have a unique incrementing ID

### Requirement: Smart working directory

The system SHALL open new terminals in the directory of the current buffer's file. For non-file buffers (e.g., file tree, dashboard), the terminal SHALL open in the editor's working directory.

#### Scenario: Terminal in buffer directory
- **WHEN** the user creates a terminal while editing `/project/src/main.lua`
- **THEN** the terminal SHALL start in `/project/src/`

#### Scenario: Terminal from non-file buffer
- **WHEN** the user creates a terminal while the file tree is focused
- **THEN** the terminal SHALL start in the editor's current working directory

### Requirement: Terminal splitting

The system SHALL support splitting the current terminal into a new pane from within terminal mode.

#### Scenario: Split terminal
- **WHEN** the user presses the split key while inside a terminal
- **THEN** a new terminal pane SHALL be created alongside the existing one

### Requirement: Vim-style terminal prompt editing

The system SHALL enable vim motions at the shell prompt line within terminal buffers, allowing users to edit commands with familiar vim bindings.

#### Scenario: Edit prompt with vim motions
- **WHEN** the user enters normal mode in a terminal buffer at the prompt line
- **THEN** vim motions (word movements, text objects, etc.) SHALL work on the prompt text

### Requirement: Terminal escape

The system SHALL provide a key binding to escape from terminal mode back to normal mode, accessible from all terminal buffers.

#### Scenario: Escape terminal mode
- **WHEN** the user presses the terminal-escape key while in terminal insert mode
- **THEN** the terminal SHALL switch to normal mode, allowing window navigation and command execution
