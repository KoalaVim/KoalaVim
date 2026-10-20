## ADDED Requirements

### Requirement: Flavor-selected terminal backend

The terminal backend SHALL follow the flavor: KoalaVim's toggleable terminal manager for `koala`, LazyVim's snacks terminal for `lazyvim`. With the `lazyvim` flavor, a single key SHALL toggle a floating/bottom terminal opened at the project root, with a separate command for the current working directory. Vim-style prompt editing and terminal escape SHALL work in both flavors.

#### Scenario: LazyVim flavor terminal toggle
- **WHEN** the flavor is `lazyvim` and the user presses the terminal key
- **THEN** a snacks terminal SHALL open in the project root directory, or be hidden if it is already focused

#### Scenario: Prompt editing in LazyVim flavor
- **WHEN** the flavor is `lazyvim` and the user enters normal mode at a shell prompt in a terminal
- **THEN** vim motions SHALL edit the prompt text

## MODIFIED Requirements

### Requirement: Multi-instance terminals

With the `koala` flavor, the system SHALL support multiple terminal instances with auto-incrementing identifiers. Each new terminal SHALL get a unique ID.

#### Scenario: Create additional terminal
- **WHEN** the flavor is `koala` and the user creates a new terminal while one already exists
- **THEN** the new terminal SHALL have a unique incrementing ID

### Requirement: Terminal splitting

With the `koala` flavor, the system SHALL support splitting the current terminal into a new pane from within terminal mode.

#### Scenario: Split terminal
- **WHEN** the flavor is `koala` and the user presses the split key while inside a terminal
- **THEN** a new terminal pane SHALL be created alongside the existing one
