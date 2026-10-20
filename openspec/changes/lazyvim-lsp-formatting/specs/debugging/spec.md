## ADDED Requirements

### Requirement: Extended debug controls

In addition to the existing controls, the system SHALL provide: run with arguments, run last configuration, pause, conditional breakpoints, moving up and down the call stack, go-to-line without executing, session selection, a widgets hover, and toggling the debug UI. Language packs SHALL contribute language-specific debug entry points (such as Python debug-test-method and debug-test-class) when debugging is enabled.

#### Scenario: Conditional breakpoint
- **WHEN** the user sets a conditional breakpoint with the expression `i == 3`
- **THEN** execution SHALL stop at that line only when the expression evaluates to true

#### Scenario: Run last configuration
- **WHEN** the user triggers run-last after a previous debug session
- **THEN** a new session SHALL start with the previous configuration

## REMOVED Requirements

### Requirement: Format-on-leave disabled during debug
**Reason**: format-on-leave has been removed. Formatting now runs only on explicit saves, and automatic saves never format, so no debug-time suppression is needed.
**Migration**: None required.
