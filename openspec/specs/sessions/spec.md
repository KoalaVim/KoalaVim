## Purpose

The session system persists and restores editor state (buffers, windows, layout) per working directory. It supports auto-save/load, named sessions, component state hooks, and configurable disable controls for specialized startup modes.

## Requirements

### Requirement: Auto-save session on exit

The system SHALL automatically save the current session (buffers, windows, layout) on editor exit. The session SHALL be associated with the current working directory.

#### Scenario: Save on quit
- **WHEN** the user quits the editor in a directory with an active session
- **THEN** the session state SHALL be saved automatically before exiting

### Requirement: Per-directory sessions

The system SHALL associate sessions with the current working directory. Each directory SHALL have at most one auto-session. The session name SHALL be derived from the directory path.

#### Scenario: Different directory different session
- **WHEN** the user opens the editor in `/project-a/` and then later in `/project-b/`
- **THEN** each directory SHALL have its own independent session

### Requirement: Session auto-load

The system SHALL automatically load the saved session when the editor starts in a directory that has one. Auto-load SHALL also trigger on editor restart.

#### Scenario: Auto-load on start
- **WHEN** the editor starts in a directory with a previously saved session
- **THEN** the session SHALL be automatically restored (buffers, windows, layout)

#### Scenario: Auto-load on restart
- **WHEN** the editor restarts (via the restart command)
- **THEN** the session for the current working directory SHALL be automatically loaded

### Requirement: Named sessions

The system SHALL support creating, loading, renaming, and deleting named sessions independent of the working directory.

#### Scenario: Save named session
- **WHEN** the user creates a named session called "feature-work"
- **THEN** the current state SHALL be saved under that name and retrievable later

#### Scenario: Load named session
- **WHEN** the user loads a named session
- **THEN** the editor state SHALL be restored to the saved session's state

### Requirement: Session list browser

The system SHALL provide a browsable list of all saved sessions, sorted by proximity to the current working directory. Session paths SHALL be displayed relative to the home directory.

#### Scenario: Browse and load session
- **WHEN** the user opens the session list
- **THEN** all saved sessions SHALL be displayed sorted by path similarity to the current directory, and selecting one SHALL load it

### Requirement: Session disable controls

The system SHALL support disabling session management in multiple ways: via environment variable, when opening specific files (not directories), or programmatically by components that manage their own state (AI mode, git mode).

#### Scenario: Disable via environment
- **WHEN** the `KOALA_NO_SESSION` environment variable is set
- **THEN** session auto-save and auto-load SHALL be completely disabled

#### Scenario: Disable for single file
- **WHEN** the editor is opened with a specific file path (not a directory)
- **THEN** session auto-save SHALL be disabled for that invocation

### Requirement: Session hooks for component state

The system SHALL fire hooks before session save and after session load, allowing components to persist and restore their own state (e.g., build configuration, debug targets, deploy directories).

#### Scenario: Component saves state
- **WHEN** a session is being saved and a component has registered a before-save hook
- **THEN** the component's hook SHALL run and its state data SHALL be included in the session

#### Scenario: Component restores state
- **WHEN** a session is loaded and a component has registered an after-load hook
- **THEN** the component's hook SHALL run with the previously saved state data

### Requirement: Session management commands

The system SHALL provide user commands for manual session operations: save current session, load current directory's session, delete current session, and all named session operations.

#### Scenario: Delete session
- **WHEN** the user triggers delete-session
- **THEN** the current directory's saved session SHALL be removed and auto-save SHALL be disabled for the current editor instance
