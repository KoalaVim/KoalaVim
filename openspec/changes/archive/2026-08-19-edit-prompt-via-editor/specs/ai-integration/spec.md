## ADDED Requirements

### Requirement: Native CLI editor via EDITOR proxy

The system SHALL inject `EDITOR` (and `VISUAL`) for AI CLI processes spawned by the sidecar so that each CLI's native "edit in editor" action opens the given file in the already-running editor instance. The proxy SHALL NOT start a nested editor process. Closing the editing split SHALL unblock the CLI so it can read the file back as the new prompt.

The existing KoalaVim edit-prompt overlay (parse terminal buffer, inject via key sequences) SHALL remain available and unchanged.

#### Scenario: CLI edit-in-editor opens the file in the running instance
- **WHEN** a sidecar-spawned AI CLI invokes `$EDITOR` on a temp file
- **THEN** that file SHALL open in a split in the running editor instance and no new editor process SHALL be started as the editor

#### Scenario: Closing the split returns control to the CLI
- **WHEN** the user saves as needed and closes the split that holds the CLI's temp file
- **THEN** the `$EDITOR` process SHALL exit successfully and the CLI SHALL be able to read the file contents as the prompt

#### Scenario: Unsaved edits are persisted before the CLI resumes
- **WHEN** the user modifies the buffer and closes the split without saving it explicitly
- **THEN** the buffer contents SHALL be written to the temp file before the `$EDITOR` process exits, so the CLI reads the edited text

#### Scenario: Failed write is reported rather than hanging the CLI
- **WHEN** the buffer cannot be written back to the temp file on close
- **THEN** the user SHALL be notified at warning level and the `$EDITOR` process SHALL still exit so the CLI is not left waiting

#### Scenario: Editor stays responsive while the CLI waits
- **WHEN** the file is open in the split and the CLI is blocked on the editor process
- **THEN** the editor SHALL remain fully interactive, including windows and buffers unrelated to the prompt

#### Scenario: Focus returns to the AI terminal
- **WHEN** the split holding the CLI's temp file is closed
- **THEN** focus SHALL return to the AI terminal window the edit was started from, when that window still exists

#### Scenario: Concurrent edit requests stay independent
- **WHEN** two AI CLI sessions each invoke `$EDITOR` on their own temp file at the same time
- **THEN** each SHALL open its own split, and closing one SHALL unblock only that CLI

#### Scenario: Unmodified close keeps the CLI's original temp contents
- **WHEN** the user closes the split without changing the buffer
- **THEN** the temp file SHALL still contain what the CLI wrote, and the `$EDITOR` process SHALL still exit so the CLI can proceed

#### Scenario: Paths with special characters
- **WHEN** the CLI passes a file path that contains spaces or other shell-special characters
- **THEN** the file SHALL still open in the running editor and the round-trip SHALL succeed

#### Scenario: RPC failure does not hang the CLI
- **WHEN** the proxy cannot reach the running editor (missing `NVIM` socket or RPC error)
- **THEN** the `$EDITOR` process SHALL exit with a non-zero status without waiting indefinitely

#### Scenario: Missing proxy does not block CLI startup
- **WHEN** the proxy script cannot be resolved on the runtime path
- **THEN** the AI CLI SHALL still start, and `EDITOR`/`VISUAL` SHALL NOT be overridden to a missing path

#### Scenario: Tool-specific editor configuration wins
- **WHEN** an AI CLI tool is configured with its own `EDITOR` or `VISUAL` value
- **THEN** that value SHALL be used for the spawned process instead of the proxy

#### Scenario: Temporary resources are cleaned up
- **WHEN** the `$EDITOR` process exits, whether the round-trip succeeded, failed, or was interrupted
- **THEN** the scratch resources it created for signalling SHALL be removed

#### Scenario: Native CLI keybind is the trigger
- **WHEN** the user presses the CLI's own edit-in-editor keybind inside the AI terminal
- **THEN** the `$EDITOR` proxy round-trip SHALL run, and the KoalaVim parse-and-inject overlay SHALL NOT be invoked as part of that keybind

#### Scenario: Existing edit-prompt overlay still works
- **WHEN** the user presses the KoalaVim edit-prompt key in the AI terminal
- **THEN** the existing parse-terminal-and-inject prompt buffer SHALL open as it does today
