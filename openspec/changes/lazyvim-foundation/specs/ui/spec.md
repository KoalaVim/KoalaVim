## MODIFIED Requirements

### Requirement: Dark color scheme

The system SHALL provide the ofirkai dark color scheme as the default, applied through LazyVim's colorscheme setting and loaded at highest priority so that all components render consistently. Plugins in the LazyVim-based stack that ofirkai does not yet style (which-key, mini.icons, mini.ai, the snacks dashboard, trouble v3 groups) SHALL receive highlight groups in ofirkai.

#### Scenario: Theme applies on startup
- **WHEN** the editor starts
- **THEN** the ofirkai color scheme SHALL be applied before any UI components render

#### Scenario: Colorscheme load failure
- **WHEN** ofirkai fails to load
- **THEN** the system SHALL fall back to a built-in colorscheme and report the error

### Requirement: Which-key popup

The system SHALL display a popup showing possible key binding continuations after a leader key press, helping users discover available commands. The popup SHALL use LazyVim's which-key configuration, including its named key groups and a command that shows buffer-local keymaps.

#### Scenario: Show continuations
- **WHEN** the user presses the leader key and pauses
- **THEN** a popup SHALL appear listing all registered key bindings that start with the leader prefix

#### Scenario: Named groups
- **WHEN** the which-key popup lists a prefix that has a registered group
- **THEN** the group SHALL be shown with its descriptive name

#### Scenario: Buffer-local keymaps
- **WHEN** the user triggers the buffer-keymaps command
- **THEN** which-key SHALL show only the keymaps local to the current buffer
