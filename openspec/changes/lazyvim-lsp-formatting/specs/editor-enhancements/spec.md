## MODIFIED Requirements

### Requirement: Automatic file saving

The system SHALL automatically save files when leaving insert mode and on text changes. Saving SHALL be skipped for hex-mode buffers and non-normal editor modes. Automatic saves SHALL NOT trigger auto-format-on-save. Write hooks other than formatting (git signs refresh, LSP did-save notifications, linters) SHALL still run on automatic saves.

#### Scenario: Auto-save on insert leave
- **WHEN** the user exits insert mode in a modified file buffer
- **THEN** the file SHALL be saved automatically

#### Scenario: Hex buffer excluded
- **WHEN** the current buffer is in hex view mode
- **THEN** auto-save SHALL not trigger

#### Scenario: Auto-save does not format
- **WHEN** an automatic save writes a buffer whose filetype has auto-format enabled
- **THEN** the buffer SHALL be written without formatting, and its auto-format setting SHALL be unchanged afterwards

#### Scenario: Explicit save still formats
- **WHEN** the user saves the same buffer explicitly with `:w`
- **THEN** the buffer SHALL be formatted before it is written
