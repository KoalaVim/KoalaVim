## Purpose

The LSP layer manages language server interactions: diagnostic display and navigation, code formatting with configurable blacklists, server configuration registry, signature help, and environment-aware behavior for remote/constrained setups.

## Requirements

### Requirement: Diagnostic navigation

The system SHALL provide commands to jump to the next/previous diagnostic (any severity) and next/previous error (error severity only). The screen SHALL center after each jump.

#### Scenario: Jump to next error
- **WHEN** the user triggers next-error navigation
- **THEN** the cursor SHALL jump to the next error-severity diagnostic and the screen SHALL center on it

#### Scenario: Jump to next diagnostic
- **WHEN** the user triggers next-diagnostic navigation
- **THEN** the cursor SHALL jump to the next diagnostic of any severity

### Requirement: Diagnostic display modes

The system SHALL support cycling between multiple diagnostic display modes: flow-style inline diagnostics, virtual lines (full-line diagnostics below the affected line), and virtual text showing only errors. The current mode SHALL persist until manually changed.

#### Scenario: Cycle diagnostic display
- **WHEN** the user triggers cycle-diagnostics-mode
- **THEN** the diagnostic display SHALL switch to the next mode in the cycle

#### Scenario: Flow diagnostics in normal mode
- **WHEN** the editor is in normal mode and flow diagnostics mode is active
- **THEN** diagnostics SHALL appear as inline indicators near the affected code

### Requirement: Formatting with blacklists

The system SHALL support code formatting via dedicated formatters with fallback to LSP formatting. Both format-on-demand and auto-format-on-save SHALL be supported. Configurable blacklists SHALL allow excluding specific formatters or filetypes from formatting.

#### Scenario: Auto-format on save
- **WHEN** a file is saved and auto-format is enabled for its filetype
- **THEN** the file SHALL be formatted using the configured formatter (or LSP fallback)

#### Scenario: Formatter blacklisted
- **WHEN** a formatter is on the format blacklist for the current filetype
- **THEN** that formatter SHALL not be used, and the system SHALL fall back to the next available formatter

#### Scenario: Filetype blacklisted
- **WHEN** the current file's type is on the auto-format filetype blacklist
- **THEN** auto-format-on-save SHALL be skipped for this file

#### Scenario: Cursor preservation
- **WHEN** async formatting completes
- **THEN** the cursor position and view offset SHALL be restored to their pre-format state

### Requirement: Diagnostic signs

The system SHALL display distinct icons in the sign column for each diagnostic severity level (error, warning, hint, info).

#### Scenario: Error sign
- **WHEN** a line has an error diagnostic
- **THEN** the error icon SHALL appear in the sign column on that line

### Requirement: LSP server configuration registry

The system SHALL provide a global registry for LSP server configurations. Language support modules SHALL register their servers and settings into this registry, and the LSP framework SHALL use it for server initialization.

#### Scenario: Register server
- **WHEN** a language module registers a server with specific settings
- **THEN** the server SHALL be started with those settings when a matching filetype is opened

### Requirement: Late-attach callback

The system SHALL support registering on-attach callbacks that also fire for LSP clients that are already active. This SHALL allow lazy-loaded components to retroactively attach to running servers.

#### Scenario: Lazy-loaded component attaches
- **WHEN** a component loads after an LSP server has already attached to a buffer
- **THEN** the component's on-attach callback SHALL fire for the already-active client

### Requirement: LSP signature help

The system SHALL display function signature help in a floating popup during insert mode. The popup SHALL be manually triggerable and SHALL appear with borders and proper formatting.

#### Scenario: Trigger signature help
- **WHEN** the user presses the signature-help key in insert mode
- **THEN** a floating popup SHALL show the current function's signature with parameter highlighting

### Requirement: Environment-aware LSP behavior

The system SHALL detect environment characteristics (remote servers, no-sudo environments) and adjust LSP behavior accordingly (e.g., skipping tools that require system-level installation).

#### Scenario: Remote environment detection
- **WHEN** the editor is running on a remote server (indicated by sentinel files)
- **THEN** the LSP configuration SHALL adapt to the available tools on that environment
