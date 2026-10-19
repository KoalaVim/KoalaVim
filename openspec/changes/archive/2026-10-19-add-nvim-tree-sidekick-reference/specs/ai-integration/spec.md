## MODIFIED Requirements

### Requirement: Context sending

The system SHALL allow sending context to the AI tool: the current file, a visual selection, or the current cursor context ("this"). Context SHALL be appropriately formatted for the AI tool's input format. Integration with the diff viewer SHALL provide additional context from diff sessions. Integration with the file explorer (nvim-tree) SHALL reference the explorer's file and directory nodes instead of the explorer buffer. When the prompt editor is open, context SHALL be inserted into the prompt editor; otherwise it SHALL be sent to the AI tool.

#### Scenario: Send file context
- **WHEN** the user triggers send-file-context
- **THEN** the current file's path and content SHALL be sent to the AI tool

#### Scenario: Send visual selection
- **WHEN** the user selects code in visual mode and triggers send-selection
- **THEN** the selected code with file path and line numbers SHALL be sent to the AI tool

#### Scenario: Send context from diff viewer
- **WHEN** the user triggers send-context while in a diff viewer panel
- **THEN** the context SHALL include the relevant file, its modification state, and any selected diff information

#### Scenario: Reference node under cursor from file explorer
- **WHEN** the user triggers send-context ("this" or "file") in the file explorer with no marked nodes and the cursor on a file or directory node
- **THEN** a reference to that node's path (cwd-relative, in the same `@path` format as file context) SHALL be sent

#### Scenario: Normal-mode send key in file explorer
- **WHEN** the user presses `<M-a>` in normal mode in the file explorer
- **THEN** the explorer node(s) SHALL be referenced as for send-context ("this") instead of toggling the AI panel
- **AND** `<M-a>` outside the file explorer SHALL keep toggling the AI panel

#### Scenario: Reference visually selected nodes from file explorer
- **WHEN** the user selects several lines in the file explorer in visual mode and triggers send-context
- **THEN** a reference for every file and directory node in the selection SHALL be sent, in tree order, separated by spaces

#### Scenario: Reference marked nodes from file explorer
- **WHEN** the user has marked nodes in the file explorer and triggers send-context in normal mode
- **THEN** a reference for every marked node SHALL be sent instead of the node under the cursor
- **AND** the explorer marks SHALL be cleared after sending

#### Scenario: Ignore non-path nodes in file explorer
- **WHEN** the user triggers send-context in the file explorer on a node without a path (e.g. the root header line)
- **THEN** nothing SHALL be sent and the user SHALL be notified that there is no node to reference

#### Scenario: Insert explorer references into prompt editor
- **WHEN** the prompt editor is open and the user triggers send-context in the file explorer
- **THEN** the references SHALL be inserted into the prompt editor at its cursor and focus SHALL move to the prompt editor
- **AND** nothing SHALL be sent directly to the AI tool
