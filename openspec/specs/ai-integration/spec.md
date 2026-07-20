## Purpose

AI integration connects external AI CLI tools (Claude, Codex, Cursor) into the editor as a sidecar panel. It provides context sending, prompt editing in a full editor buffer, persistent prompt history, fast-typing detection, next-edit suggestions, and window management for the AI workflow.

## Requirements

### Requirement: AI CLI sidecar panel

The system SHALL integrate external AI command-line tools into a side panel within the editor. The panel SHALL support toggling visibility, showing/hiding, and selecting between multiple installed AI tools. Each tool session SHALL be independently manageable (attach, detach).

#### Scenario: Toggle AI panel
- **WHEN** the user presses the AI toggle key
- **THEN** the AI sidecar panel SHALL open (or close if already open)

#### Scenario: Select AI tool
- **WHEN** the user triggers tool selection
- **THEN** a picker SHALL show all available AI CLI tools, and selecting one SHALL switch the active tool

#### Scenario: Detach session
- **WHEN** the user detaches the current AI session
- **THEN** the session SHALL be disconnected from the panel, freeing it for a new session

### Requirement: Default AI tool management

The system SHALL support configuring a default AI tool via the config system or at runtime. When a default is set, AI operations SHALL use it without prompting. When no default is set, the user SHALL be prompted to select a tool.

#### Scenario: Default from config
- **WHEN** the config sets `ai.default_tool` to a tool name
- **THEN** that tool SHALL be used for all AI operations without prompting

#### Scenario: No default prompts selection
- **WHEN** no default AI tool is configured and the user triggers an AI operation
- **THEN** a tool selection picker SHALL appear

### Requirement: Context sending

The system SHALL allow sending context to the AI tool: the current file, a visual selection, or the current cursor context ("this"). Context SHALL be appropriately formatted for the AI tool's input format. Integration with the diff viewer SHALL provide additional context from diff sessions.

#### Scenario: Send file context
- **WHEN** the user triggers send-file-context
- **THEN** the current file's path and content SHALL be sent to the AI tool

#### Scenario: Send visual selection
- **WHEN** the user selects code in visual mode and triggers send-selection
- **THEN** the selected code with file path and line numbers SHALL be sent to the AI tool

#### Scenario: Send context from diff viewer
- **WHEN** the user triggers send-context while in a diff viewer panel
- **THEN** the context SHALL include the relevant file, its modification state, and any selected diff information

### Requirement: Prompt editing in editor buffer

The system SHALL support composing and editing AI prompts in a regular editor buffer instead of the terminal, providing full editing capabilities (vim motions, text objects, file picker, buffer picker). The buffer SHALL support submitting the prompt, recalling prompt history, and attaching file references.

#### Scenario: Open prompt editor
- **WHEN** the user presses the edit-prompt key while in the AI terminal
- **THEN** a split buffer SHALL open for composing the prompt with full editor capabilities

#### Scenario: Submit prompt
- **WHEN** the user finishes editing in the prompt buffer and submits
- **THEN** the prompt content SHALL be sent to the AI tool and the prompt buffer SHALL close

#### Scenario: Attach file reference
- **WHEN** the user presses the file-picker key inside the prompt buffer
- **THEN** a file picker SHALL open and the selected file's path SHALL be inserted into the prompt

### Requirement: Prompt history

The system SHALL maintain a persistent per-workspace, per-branch history of prompts sent to AI tools. The history SHALL be stored as structured records with timestamps, tool name, and branch information. A history picker SHALL support browsing at local (current branch), workspace (all branches), and global (all workspaces) scopes.

#### Scenario: Record prompt
- **WHEN** the user sends a prompt to the AI tool
- **THEN** the prompt SHALL be recorded with timestamp, tool name, cwd, and branch

#### Scenario: Browse local history
- **WHEN** the user opens prompt history in local scope
- **THEN** prompts from the current branch SHALL be shown in reverse chronological order

#### Scenario: Recall prompt from history
- **WHEN** the user selects a prompt from history
- **THEN** it SHALL open in the prompt editor buffer for editing and re-sending

#### Scenario: Switch scope
- **WHEN** the user presses the scope-toggle key while in the history picker
- **THEN** the picker SHALL switch between local, workspace, and global scopes

### Requirement: Prompt navigation

The system SHALL support navigating between prompts within the AI terminal buffer, jumping to the next/previous prompt marker.

#### Scenario: Jump to next prompt
- **WHEN** the user triggers next-prompt navigation in the AI terminal
- **THEN** the cursor SHALL jump to the next prompt marker in the terminal buffer

### Requirement: AI panel window management

The system SHALL support toggling the AI panel between half-screen and maximized width, and zooming the AI panel into a dedicated tab page. Window options specific to the AI terminal (terminal rendering settings) SHALL not leak into regular editor windows.

#### Scenario: Toggle max width
- **WHEN** the user toggles max/half size on the AI panel
- **THEN** the panel width SHALL switch between approximately half the screen and 95% of the screen

#### Scenario: Zoom to tab
- **WHEN** the user zooms the AI panel
- **THEN** the panel SHALL move to a new dedicated tab page, and zooming again SHALL return it

#### Scenario: Window option isolation
- **WHEN** a regular editor buffer is opened in a window that previously held the AI terminal
- **THEN** terminal-specific window options SHALL be cleaned up so the editor buffer renders normally

### Requirement: Fast-typing detection

The system SHALL detect when the user is typing quickly in the AI terminal (exceeding a configurable keystroke count within a time window) and automatically switch to the prompt editor buffer for a better editing experience. Keystrokes typed during the transition SHALL be captured and inserted into the prompt buffer.

#### Scenario: Fast typing triggers prompt editor
- **WHEN** the user types more than the configured number of printable characters within the configured time window in the AI terminal
- **THEN** the prompt editor buffer SHALL automatically open with the already-typed characters pre-filled

#### Scenario: Configurable thresholds
- **WHEN** the config sets `ai.auto_edit_prompt.count` to 5 and `ai.auto_edit_prompt.window_ms` to 800
- **THEN** fast-typing detection SHALL trigger after 5 keystrokes within 800ms

### Requirement: Next-edit suggestions (NES)

The system SHALL support inline AI-powered next-edit suggestions that can be toggled on and off. When enabled, the AI SHALL suggest the next likely edit based on context.

#### Scenario: Toggle NES
- **WHEN** the user toggles NES
- **THEN** inline next-edit suggestions SHALL be enabled (or disabled if already on)

### Requirement: File navigation from AI terminal

The system SHALL support navigating to files referenced in AI terminal output. The navigation SHALL support jumping to specific line numbers when the reference includes them (e.g., `file.lua:42`). Files SHALL open in the nearest editor window, not in the terminal pane.

#### Scenario: Go to file with line number
- **WHEN** the cursor is on a file reference `src/main.lua:42` in the AI terminal and the user triggers go-to-file
- **THEN** `src/main.lua` SHALL open in the nearest editor window with the cursor on line 42

#### Scenario: Go to file without line number
- **WHEN** the cursor is on a file path `src/main.lua` in the AI terminal and the user triggers go-to-file
- **THEN** `src/main.lua` SHALL open in the nearest editor window
