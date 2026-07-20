## Purpose

The debugging system integrates the Debug Adapter Protocol (DAP) for multi-language debugging: breakpoint management, step controls, expression evaluation, inline variable display, a debug UI with scopes/watches/stacks panels, and persistent debug target configuration.

## Requirements

### Requirement: Debug adapter support

The system SHALL integrate with the Debug Adapter Protocol (DAP) to support debugging for multiple languages. Pre-configured adapters SHALL be provided for C/C++/Rust (via codelldb), C (remote gdb), Go (remote delve), and Python (with virtual environment detection).

#### Scenario: Python venv detection
- **WHEN** the user starts a Python debug session in a project with a virtual environment
- **THEN** the debug adapter SHALL automatically detect and use the Python interpreter from the virtual environment

#### Scenario: C/Rust debugging
- **WHEN** the user starts a debug session for a C or Rust program
- **THEN** the codelldb adapter SHALL be used with appropriate configuration

### Requirement: Debug UI

The system SHALL provide a debug UI with panels for: scopes/local variables, REPL, watches, breakpoints, and call stacks. The UI SHALL open in a new tab on debug start and close on termination.

#### Scenario: UI opens on debug start
- **WHEN** a debug session starts
- **THEN** a new tab SHALL open with the debug UI panels arranged for the session

#### Scenario: UI closes on termination
- **WHEN** the debug session terminates
- **THEN** the debug UI tab SHALL close automatically

### Requirement: Breakpoint management

The system SHALL support toggling breakpoints, clearing all breakpoints, navigating between breakpoints, and jumping to the DAP-stopped location. Breakpoints SHALL be visually indicated in the sign column.

#### Scenario: Toggle breakpoint
- **WHEN** the user presses the breakpoint toggle key on a line
- **THEN** a breakpoint SHALL be set (or removed if one exists) and a visual indicator SHALL appear in the sign column

#### Scenario: Navigate between breakpoints
- **WHEN** the user triggers next-breakpoint navigation
- **THEN** the cursor SHALL jump to the next breakpoint in the current file

#### Scenario: Clear all breakpoints
- **WHEN** the user triggers clear-all-breakpoints
- **THEN** all breakpoints in all files SHALL be removed

### Requirement: Step controls

The system SHALL provide debug stepping controls: continue, terminate, close, step over, step into, and step out. The screen SHALL auto-center after each step operation.

#### Scenario: Step over
- **WHEN** the user triggers step-over during an active debug session
- **THEN** execution SHALL advance to the next line (stepping over function calls) and the screen SHALL center on the new position

#### Scenario: Continue
- **WHEN** the user triggers continue
- **THEN** execution SHALL resume until the next breakpoint or program end

### Requirement: Expression evaluation

The system SHALL support evaluating expressions during a debug session: the expression under the cursor or a visual selection. Results SHALL be displayed in a floating popup.

#### Scenario: Evaluate word under cursor
- **WHEN** the cursor is on a variable name during a debug session and the user triggers evaluate
- **THEN** the variable's current value SHALL be displayed in a floating popup

#### Scenario: Evaluate visual selection
- **WHEN** the user selects an expression in visual mode during a debug session and triggers evaluate
- **THEN** the expression's result SHALL be displayed in a floating popup

### Requirement: Inline variable values

The system SHALL display variable values inline as virtual text next to the variables during an active debug session.

#### Scenario: Show inline values
- **WHEN** a debug session is active and execution is paused
- **THEN** the current values of in-scope variables SHALL appear as virtual text next to their definitions

### Requirement: Debug executable and arguments persistence

The system SHALL remember the last debugged executable path and arguments across invocations. The user SHALL be prompted to choose the file and arguments, with the previous values as defaults.

#### Scenario: Remember last debugged file
- **WHEN** the user starts a new debug session
- **THEN** the file chooser SHALL default to the previously debugged executable

#### Scenario: Session persistence
- **WHEN** the editor is closed and reopened
- **THEN** the last debugged file and arguments SHALL be restored from the session data

### Requirement: Format-on-leave disabled during debug

The system SHALL disable auto-format-on-leave during active debug sessions to prevent interference with debug state.

#### Scenario: No format during debug
- **WHEN** a debug session is active and the user switches buffers
- **THEN** auto-format-on-leave SHALL be suppressed

### Requirement: Debug REPL

The system SHALL provide a debug REPL for interactive expression evaluation during debug sessions. The REPL SHALL open in a zoomed split view.

#### Scenario: Open REPL
- **WHEN** the user triggers open-REPL during a debug session
- **THEN** the REPL SHALL open in a zoomed split, allowing interactive expression evaluation

### Requirement: Run to cursor

The system SHALL support running execution to the current cursor position without setting a persistent breakpoint.

#### Scenario: Run to cursor
- **WHEN** the user triggers run-to-cursor on line 42
- **THEN** execution SHALL continue until reaching line 42, then pause
