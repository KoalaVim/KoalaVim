## Purpose

The UI layer provides all visual components: color scheme, status line, buffer line (tab bar), file explorer tree, dashboard, notification system, command-line UI, indent guides, which-key popup, breadcrumb winbar, and window decorations. It defines how information is presented to the user across the entire editor.

## Requirements

### Requirement: Dark color scheme

The system SHALL provide a curated dark color scheme as the default, loaded at highest priority to ensure consistent visuals across all components.

#### Scenario: Theme applies on startup
- **WHEN** the editor starts
- **THEN** the dark color scheme SHALL be applied before any UI components render

### Requirement: Indent guides

The system SHALL display visual indentation guide lines in the editor. The current scope level SHALL be highlighted distinctly from other indentation levels.

#### Scenario: Scope highlighting
- **WHEN** the cursor is inside a nested code block
- **THEN** the indent guide for the current scope SHALL be visually distinct from surrounding guides

### Requirement: Enhanced input and select UI

The system SHALL replace the default input and selection prompts with floating window UIs. Input prompts SHALL start in normal mode for immediate editing control.

#### Scenario: Select prompt
- **WHEN** a component triggers `vim.ui.select()` with a list of options
- **THEN** a floating window SHALL appear with the options, supporting fuzzy filtering and keyboard navigation

### Requirement: File explorer tree

The system SHALL provide a side-panel file tree with adaptive width, relative line numbers, and git status indicators. The tree SHALL support search, find/replace, and git history scoped to a directory.

#### Scenario: Toggle file tree
- **WHEN** the user triggers the file tree toggle
- **THEN** the file tree panel SHALL open on the left side (or close if already open)

#### Scenario: Locate current file
- **WHEN** the user triggers locate-in-tree
- **THEN** the file tree SHALL expand to and highlight the current buffer's file

#### Scenario: Directory-scoped operations
- **WHEN** the user triggers search, find/replace, or git history on a directory node in the tree
- **THEN** the operation SHALL be scoped to that directory's contents

### Requirement: Status line

The system SHALL display a comprehensive status line showing: mode indicator, git branch, diff stats, diagnostics count, filename, macro recording indicator, LSP reference/definition counts, search count, tabs/spaces indicator, session status, active LSP server, git blame for the current line, filetype, cursor position, and scroll progress.

#### Scenario: Mode-specific colors
- **WHEN** the editor is in insert mode vs. normal mode vs. visual mode
- **THEN** the mode indicator color SHALL change to reflect the current mode

#### Scenario: Git blame display
- **WHEN** the cursor is on a line in a git-tracked file
- **THEN** the status line SHALL show the author and relative date of the last commit that modified that line

#### Scenario: Half-screen adaptation
- **WHEN** the terminal width is at or below half the full-screen width
- **THEN** the status line SHALL switch to an icons-only compact mode

### Requirement: Buffer line (tab bar)

The system SHALL display a tab bar showing open buffers with ordinal numbers, allowing direct jump to any buffer by number. Buffers SHALL be navigable with cycling keys and reorderable.

#### Scenario: Jump to buffer by number
- **WHEN** the user presses the leader key followed by a digit (1-0)
- **THEN** the editor SHALL switch to the buffer at that ordinal position in the tab bar

#### Scenario: Cycle buffers
- **WHEN** the user presses the buffer-cycle keys
- **THEN** the active buffer SHALL cycle to the next/previous buffer in the tab bar

### Requirement: Enhanced command UI

The system SHALL replace the default command line with a floating UI. LSP signature help and hover documentation SHALL render with borders and scroll support. Noisy/redundant messages (search count, write confirmation, pattern-not-found, undo line counts) SHALL be suppressed.

#### Scenario: Hover doc scrolling
- **WHEN** an LSP hover popup is visible and the user presses the scroll keys
- **THEN** the hover content SHALL scroll up or down within the popup

#### Scenario: Disable via environment
- **WHEN** the `KOALA_NO_NOICE` environment variable is set
- **THEN** the enhanced command UI SHALL be disabled and the default command line SHALL be used

### Requirement: LSP progress indicator

The system SHALL display a floating progress spinner for ongoing LSP operations (indexing, analysis, etc.).

#### Scenario: Show progress
- **WHEN** an LSP server reports progress on a long-running operation
- **THEN** a floating progress indicator SHALL appear and dismiss when the operation completes

### Requirement: Dashboard

The system SHALL display a startup screen with ASCII art branding and shortcut buttons for: load session, session list, AI assistant, file tree, find file, find text, recent files, git status, git diff, config editing, update, changelog, and quit. Startup time SHALL be displayed.

#### Scenario: Dashboard on empty start
- **WHEN** the editor starts with no file arguments
- **THEN** the dashboard SHALL display with all shortcut buttons and the startup time

#### Scenario: Update notification on dashboard
- **WHEN** the dashboard is displayed and upstream updates are available
- **THEN** a notification SHALL appear on the dashboard indicating updates are available

### Requirement: Which-key popup

The system SHALL display a popup showing possible key binding continuations after a leader key press, helping users discover available commands.

#### Scenario: Show continuations
- **WHEN** the user presses the leader key and pauses
- **THEN** a popup SHALL appear listing all registered key bindings that start with the leader prefix

### Requirement: Window separator highlighting

The system SHALL visually highlight the window separator of the currently focused window, making it easy to identify the active split.

#### Scenario: Active window indication
- **WHEN** focus moves to a different split
- **THEN** the window separator of the newly focused window SHALL be highlighted

### Requirement: Animated cursor

The system SHALL provide smooth cursor movement animation. Animation SHALL be disabled in GUI embedding environments (e.g., Neovide) that provide their own cursor animation.

#### Scenario: Animation in terminal
- **WHEN** the cursor moves in a terminal-based editor session
- **THEN** the cursor SHALL animate smoothly to its new position

#### Scenario: Disabled in GUI
- **WHEN** the editor is running inside a GUI wrapper that provides its own cursor animation
- **THEN** the built-in cursor animation SHALL be disabled

### Requirement: Notification system

The system SHALL provide toast-style notifications with history viewing. Notifications SHALL support different severity levels and configurable display duration. A history viewer SHALL allow reviewing past notifications.

#### Scenario: View notification history
- **WHEN** the user triggers the notification history command
- **THEN** all past notifications from the current session SHALL be displayed

#### Scenario: Dismiss all notifications
- **WHEN** the user triggers the dismiss-all command
- **THEN** all visible notifications SHALL be cleared

### Requirement: File type icons

The system SHALL display filetype-specific icons (devicons) in the file tree, buffer line, status line, and pickers.

#### Scenario: Icon in buffer line
- **WHEN** a `.lua` file is open and shown in the buffer line
- **THEN** the Lua filetype icon SHALL appear next to the buffer name

### Requirement: Custom status column

The system SHALL render a custom sign/number/fold column combining signs, line numbers, and fold indicators in a compact layout.

#### Scenario: Fold and sign coexist
- **WHEN** a line has both a diagnostic sign and is on a fold boundary
- **THEN** both the sign and fold indicator SHALL be visible in the status column

### Requirement: Winbar with breadcrumbs

The system SHALL display a winbar (top bar per window) showing the file name and LSP navigation breadcrumbs (namespace > class > function). Inactive windows SHALL show a relative file path with inline diagnostics.

#### Scenario: Active window breadcrumbs
- **WHEN** the cursor is inside a function within a class
- **THEN** the winbar SHALL display the file name followed by breadcrumbs: class > function

#### Scenario: Inactive window info
- **WHEN** a window is not focused
- **THEN** its winbar SHALL show the relative file path with any inline diagnostic indicators
