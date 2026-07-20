## Purpose

Navigation covers the keybinding scheme and window management: split creation/closing/navigation, tab and tabpage management, cross-pane navigation, yanking/clipboard integration, search enhancements, file navigation, deploy commands, editor restart, and various quality-of-life navigation behaviors.

## Requirements

### Requirement: Split management

The system SHALL provide commands for creating, closing, and navigating between splits. Smart splitting SHALL be context-aware: splitting from an AI terminal SHALL preserve terminal window options; splitting from a regular buffer SHALL perform a standard split. Closing a split SHALL also delete the buffer if it's not visible in any other window.

#### Scenario: Smart split from AI terminal
- **WHEN** the user triggers a vertical split while in the AI terminal pane
- **THEN** a new split SHALL be created and terminal-specific window options SHALL be preserved on the terminal side and cleaned up on the new editor side

#### Scenario: Close split deletes hidden buffer
- **WHEN** the user closes a split and the buffer is not visible in any other window
- **THEN** the buffer SHALL be deleted along with the window

#### Scenario: Split-if-not-exist
- **WHEN** the user triggers split-if-not-exist in a direction where a split already exists
- **THEN** the existing split SHALL be reused instead of creating a new one

### Requirement: Tab management

The system SHALL provide keybindings for buffer tab navigation (ordinal jump 1-10, cycle, move, switch to last), vim tabpage navigation (1-10, last, cycle), and tab creation/closing.

#### Scenario: Jump to buffer by ordinal
- **WHEN** the user presses leader followed by digit `3`
- **THEN** the third buffer in the buffer line SHALL become active

#### Scenario: Switch to last active buffer
- **WHEN** the user presses the last-buffer key
- **THEN** the editor SHALL switch to the previously active buffer

#### Scenario: Navigate tabpages
- **WHEN** the user presses the tabpage navigation keys
- **THEN** the editor SHALL cycle through vim tabpages

#### Scenario: Create new tabpage
- **WHEN** the user presses the new-tab key
- **THEN** a new empty tabpage SHALL be created

### Requirement: Close-all-but-current

The system SHALL provide commands to close all buffers except the current one, close all buffers to the left, and close all buffers to the right of the current buffer in the tab bar.

#### Scenario: Close all but current
- **WHEN** the user triggers close-all-but-current
- **THEN** all buffers except the current one SHALL be closed (including hidden unlisted buffers)

### Requirement: Yanking and clipboard integration

The system SHALL provide distinct keybindings for OS clipboard operations (yank to clipboard, paste from clipboard) separate from the default register. Visual-mode paste SHALL use the black-hole register to prevent overwriting. Delete and change operations SHALL have black-hole variants to avoid polluting the yank register.

#### Scenario: Yank to OS clipboard
- **WHEN** the user presses the clipboard-yank key in visual mode
- **THEN** the selected text SHALL be copied to the OS clipboard

#### Scenario: Paste from OS clipboard
- **WHEN** the user presses the clipboard-paste key
- **THEN** text from the OS clipboard SHALL be pasted at the cursor

#### Scenario: Delete without yanking
- **WHEN** the user presses the black-hole-delete key
- **THEN** the text SHALL be deleted without being stored in any register

#### Scenario: WSL clipboard support
- **WHEN** the editor is running in WSL
- **THEN** clipboard operations SHALL use `win32yank.exe` for OS clipboard integration

### Requirement: Search enhancements

The system SHALL provide search improvements: auto-center after `n`/`N` navigation, clear search highlight on demand, and search-current-word without jumping to the next match.

#### Scenario: Search without jumping
- **WHEN** the user triggers search-current-word
- **THEN** the word under the cursor SHALL be highlighted across the buffer without moving the cursor

#### Scenario: Clear highlight
- **WHEN** the user presses the clear-highlight key
- **THEN** all search highlighting SHALL be dismissed

### Requirement: Line navigation for wrapped lines

`j` and `k` without a count SHALL move through visual (wrapped) lines rather than logical lines. With a count, they SHALL move through logical lines as normal.

#### Scenario: Navigate wrapped lines
- **WHEN** the user presses `j` without a count on a wrapped line
- **THEN** the cursor SHALL move to the next visual line (which may be the same logical line)

#### Scenario: Navigate with count
- **WHEN** the user presses `5j`
- **THEN** the cursor SHALL move 5 logical lines down

### Requirement: Jump centering

The system SHALL automatically center the screen after jump-list navigation (`<C-o>`, `<C-i>`).

#### Scenario: Center after jump back
- **WHEN** the user presses `<C-o>` to jump back in the jump list
- **THEN** the screen SHALL center on the cursor after the jump

### Requirement: Arrow key scrolling

Arrow keys SHALL scroll the viewport rather than move the cursor, providing an alternative scroll mechanism.

#### Scenario: Arrow scrolls viewport
- **WHEN** the user presses the down arrow key
- **THEN** the viewport SHALL scroll down without moving the cursor relative to the buffer

### Requirement: Spell check toggle

The system SHALL provide a key to toggle spell checking on and off. Spell check SHALL be automatically enabled for specific filetypes (git commits, markdown, mail, plantuml, AI prompts).

#### Scenario: Auto-enable for git commit
- **WHEN** the user opens a git commit message buffer
- **THEN** spell check SHALL be automatically enabled

#### Scenario: Manual toggle
- **WHEN** the user presses the spell-toggle key
- **THEN** spell check SHALL toggle on or off for the current buffer

### Requirement: File navigation with line numbers

`gf` SHALL be enhanced to parse `file:LINE` and `file:LNNN` patterns, jumping to both the file and the specified line number. The original `gf` behavior SHALL remain available on a separate binding.

#### Scenario: Go to file with line
- **WHEN** the cursor is on `config/init.lua:42` and the user presses `gf`
- **THEN** `config/init.lua` SHALL open with the cursor on line 42

### Requirement: Search-and-replace rename

The system SHALL provide a quick search-and-replace rename for the word under the cursor or visual selection, pre-populating the substitute command.

#### Scenario: Rename word under cursor
- **WHEN** the user triggers rename on a word
- **THEN** a search-and-replace command SHALL be pre-populated with the word, ready for the user to type the replacement

### Requirement: Deploy command

The system SHALL provide a keybinding to run a `deploy` command in a toggle-terminal. The deploy target directory SHALL be configurable and persist across sessions.

#### Scenario: Trigger deploy
- **WHEN** the user presses the deploy key
- **THEN** a terminal SHALL open running the `deploy` command in the configured directory

#### Scenario: Reset deploy directory
- **WHEN** the user triggers reset-deploy
- **THEN** the deploy terminal SHALL be reconfigured to use the current directory

### Requirement: Editor restart

The system SHALL provide a keybinding to restart the editor. The restart SHALL save all files, create a restart marker for the external launcher, and close the editor. The launcher SHALL detect the marker and relaunch.

#### Scenario: Restart editor
- **WHEN** the user presses the restart key
- **THEN** all files SHALL be saved, the AI sidecar SHALL be closed if present, and the editor SHALL exit with a marker signaling the launcher to relaunch

### Requirement: Lua file hot-reload

The system SHALL support reloading the current Lua file during development without restarting the editor.

#### Scenario: Reload Lua file
- **WHEN** the user presses the reload key while editing a Lua file
- **THEN** the file SHALL be re-required, applying any changes immediately

### Requirement: Automatic buffer cleanup

The system SHALL automatically quit when specific conditions are met: when the only remaining window is the file tree, or when the AI terminal is the last buffer with only empty/unnamed buffers remaining.

#### Scenario: Auto-quit with only file tree
- **WHEN** all editor buffers are closed and only the file tree remains
- **THEN** the editor SHALL automatically quit

#### Scenario: Auto-quit with only AI terminal
- **WHEN** the AI terminal is the last buffer and all other buffers are empty or unnamed
- **THEN** the editor SHALL automatically quit

### Requirement: Yank highlighting

The system SHALL briefly highlight the yanked region after a yank operation to provide visual feedback.

#### Scenario: Flash on yank
- **WHEN** the user yanks text
- **THEN** the yanked region SHALL be highlighted for approximately 350ms

### Requirement: Help and man pages in vertical splits

The system SHALL open help pages and man pages in vertical splits rather than horizontal splits for better readability on wide screens.

#### Scenario: Open help in vsplit
- **WHEN** the user opens a help page
- **THEN** it SHALL appear in a vertical split

### Requirement: Custom filetype associations

The system SHALL register custom filetype associations for files not natively recognized: `.mdc` as markdown, `.tmux` as tmux config, `.tofu` as terraform.

#### Scenario: Open .mdc file
- **WHEN** the user opens a `.mdc` file
- **THEN** it SHALL be treated as markdown with full markdown support (syntax, LSP, etc.)

### Requirement: Mouse bindings

The system SHALL provide mouse bindings for code navigation: middle-click for go-to-definition, ctrl-click for go-to-definition in split, double-right-click for navigate-back.

#### Scenario: Middle-click go-to-definition
- **WHEN** the user middle-clicks on a symbol
- **THEN** the editor SHALL navigate to that symbol's definition

### Requirement: Quickfix height

The system SHALL set the quickfix window to a compact height (6 lines) to preserve editing space.

#### Scenario: Quickfix opens at 6 lines
- **WHEN** the quickfix window opens
- **THEN** its height SHALL be 6 lines

### Requirement: Half-screen layout adaptation

The system SHALL detect when the terminal is at half-screen width and automatically adjust: switch vertical splits to horizontal, and switch the status line to compact/icons-only mode.

#### Scenario: Half-screen detected
- **WHEN** the terminal width drops to half of the configured full-screen width
- **THEN** vertical splits SHALL be flipped to horizontal and the status line SHALL switch to icons-only mode

#### Scenario: Full-screen restored
- **WHEN** the terminal width returns to full-screen
- **THEN** layouts and status line SHALL revert to their full-width configurations
