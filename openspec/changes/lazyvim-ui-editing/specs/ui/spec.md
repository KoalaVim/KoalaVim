## MODIFIED Requirements

### Requirement: Status line

The system SHALL display a status line whose layout depends on the flavor. With the `koala` flavor, it SHALL show: mode indicator, git branch, diff stats, diagnostics count, filename, macro recording indicator, LSP reference/definition counts, search count, tabs/spaces indicator, session status, active LSP server, git blame for the current line, filetype, cursor position and scroll progress. With the `lazyvim` flavor, it SHALL use LazyVim's status line layout styled with the ofirkai theme.

#### Scenario: Mode-specific colors
- **WHEN** the editor is in insert mode vs. normal mode vs. visual mode
- **THEN** the mode indicator color SHALL change to reflect the current mode

#### Scenario: Git blame display
- **WHEN** the flavor is `koala` and the cursor is on a line in a git-tracked file
- **THEN** the status line SHALL show the author and relative date of the last commit that modified that line

#### Scenario: Half-screen adaptation
- **WHEN** the flavor is `koala` and the terminal width is at or below half the full-screen width
- **THEN** the status line SHALL switch to an icons-only compact mode

#### Scenario: LazyVim flavor layout
- **WHEN** the flavor is `lazyvim`
- **THEN** the status line SHALL show LazyVim's sections (root directory, diagnostics, filename, noice/dap/lazy status, diff, location) in ofirkai colors

### Requirement: Buffer line (tab bar)

The system SHALL display a tab bar showing open buffers with ordinal numbers, allowing a direct jump to any buffer by number. Buffers SHALL be navigable with cycling keys and reorderable. With the `koala` flavor the tab bar SHALL use KoalaVim's ofirkai tabline styling. With the `lazyvim` flavor it SHALL use LazyVim's bufferline configuration with ofirkai colors.

#### Scenario: Jump to buffer by number
- **WHEN** the user presses the leader key followed by a digit (1-0)
- **THEN** the editor SHALL switch to the buffer at that ordinal position in the tab bar

#### Scenario: Cycle buffers
- **WHEN** the user presses the buffer-cycle keys
- **THEN** the active buffer SHALL cycle to the next/previous buffer in the tab bar

### Requirement: Dashboard

The system SHALL display a startup screen when the editor starts with no file arguments. With the `koala` flavor, it SHALL be KoalaVim's dashboard with ASCII art branding and shortcut buttons for: load session, session list, AI assistant, file tree, find file, find text, recent files, git status, git diff, config editing, update, changelog and quit. With the `lazyvim` flavor, it SHALL be LazyVim's dashboard extended with KoalaVim's AI, git diff, update and changelog buttons. Startup time SHALL be displayed in both. Closing the dashboard SHALL emit a flavor-independent event.

#### Scenario: Dashboard on empty start
- **WHEN** the editor starts with no file arguments
- **THEN** the flavor's dashboard SHALL display with its shortcut buttons and the startup time

#### Scenario: Update notification on dashboard
- **WHEN** the dashboard is displayed and upstream updates are available
- **THEN** a notification SHALL appear on the dashboard indicating updates are available

#### Scenario: Dashboard closed event
- **WHEN** the dashboard is closed in either flavor
- **THEN** the `KoalaDashboardClosed` user event SHALL fire
