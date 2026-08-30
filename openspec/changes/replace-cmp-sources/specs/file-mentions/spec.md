## ADDED Requirements

### Requirement: @-triggered file mention insertion

The system SHALL provide @-triggered file path completion and insertion via filemention.nvim. When the user types `@` followed by a partial filename, matching file paths from the project SHALL be suggested.

#### Scenario: Trigger file mention completion
- **WHEN** the user types `@` followed by at least one character in insert mode
- **THEN** a list of matching file paths from the project SHALL be presented for selection

#### Scenario: Insert selected file path
- **WHEN** the user selects a file from the mention suggestions
- **THEN** the file path SHALL be inserted at the cursor position replacing the `@` trigger and partial input
