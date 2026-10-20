## MODIFIED Requirements

### Requirement: Arrow key scrolling

Under the `koala` flavor, arrow keys SHALL scroll the viewport rather than move the cursor, providing an alternative scroll mechanism. Under the `lazyvim` flavor, the up/down arrow keys SHALL move through wrapped lines.

#### Scenario: Arrow scrolls viewport
- **WHEN** the flavor is `koala` and the user presses the down arrow key
- **THEN** the viewport SHALL scroll down without moving the cursor relative to the buffer

#### Scenario: Arrow moves under LazyVim flavor
- **WHEN** the flavor is `lazyvim` and the user presses the down arrow key on a wrapped line
- **THEN** the cursor SHALL move to the next visual line

### Requirement: Search enhancements

The system SHALL provide search improvements: clear search highlight on demand, and search-current-word without jumping to the next match. Under the `koala` flavor, the screen SHALL auto-center after `n`/`N` navigation. Under the `lazyvim` flavor, `n`/`N` SHALL always search in the same direction regardless of the original search direction, and SHALL open folds at the match.

#### Scenario: Search without jumping
- **WHEN** the user triggers search-current-word
- **THEN** the word under the cursor SHALL be highlighted across the buffer without moving the cursor

#### Scenario: Clear highlight
- **WHEN** the user presses the clear-highlight key
- **THEN** all search highlighting SHALL be dismissed

#### Scenario: Centered search navigation
- **WHEN** the flavor is `koala` and the user presses `n`
- **THEN** the cursor SHALL move to the next match and the screen SHALL center on it

### Requirement: Yanking and clipboard integration

The system SHALL provide distinct keybindings for OS clipboard operations (yank to clipboard, paste from clipboard) separate from the default register. Visual-mode paste SHALL use the black-hole register to prevent overwriting. Delete and change operations SHALL have black-hole variants to avoid polluting the yank register. These SHALL be available under both flavors, on flavor-specific keys where the KoalaVim key is taken by LazyVim.

#### Scenario: Yank to OS clipboard
- **WHEN** the user presses the clipboard-yank key in visual mode
- **THEN** the selected text SHALL be copied to the OS clipboard

#### Scenario: Paste from OS clipboard
- **WHEN** the user presses the clipboard-paste key
- **THEN** text from the OS clipboard SHALL be pasted at the cursor

#### Scenario: Delete without yanking
- **WHEN** the user presses the black-hole-delete key for the active flavor
- **THEN** the text SHALL be deleted without being stored in any register

#### Scenario: WSL clipboard support
- **WHEN** the editor is running in WSL
- **THEN** clipboard operations SHALL use `win32yank.exe` for OS clipboard integration

### Requirement: Deploy command

The system SHALL provide a keybinding to run a `deploy` command in a toggle-terminal, under both flavors (on a flavor-specific key). The deploy target directory SHALL be configurable and persist across sessions.

#### Scenario: Trigger deploy
- **WHEN** the user presses the deploy key for the active flavor
- **THEN** a terminal SHALL open running the `deploy` command in the configured directory

#### Scenario: Reset deploy directory
- **WHEN** the user triggers reset-deploy
- **THEN** the deploy terminal SHALL be reconfigured to use the current directory
