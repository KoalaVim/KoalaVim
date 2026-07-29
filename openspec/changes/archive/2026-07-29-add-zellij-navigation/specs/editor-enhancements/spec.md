## MODIFIED Requirements

### Requirement: Cross-pane navigation

The system SHALL provide unified window navigation that works across editor splits and terminal multiplexer panes (tmux, wezterm, zellij). The same key bindings SHALL move focus seamlessly between editor and multiplexer boundaries.

When several multiplexers are nested, the system SHALL drive the innermost one — the multiplexer that owns the pane the editor occupies. Specifically, when the editor runs inside a Zellij session the Zellij backend SHALL be used regardless of any outer multiplexer.

Handoff to the multiplexer SHALL NOT block the editor. When a multiplexer handoff fails, the system SHALL notify the user at warning level rather than failing silently.

#### Scenario: Navigate from editor to multiplexer pane
- **WHEN** the user presses the right-navigation key while in the rightmost editor split
- **THEN** focus SHALL move to the adjacent multiplexer pane to the right

#### Scenario: Navigate between editor splits
- **WHEN** the user presses a navigation key and an editor split exists in that direction
- **THEN** focus SHALL move to that split and no multiplexer command SHALL be issued

#### Scenario: Navigation does not cross multiplexer tabs
- **WHEN** the user presses a navigation key in any direction while at the edge of both the editor layout and the multiplexer's pane layout
- **THEN** focus SHALL remain where it is and SHALL NOT move to another multiplexer tab or window

#### Scenario: Zellij takes priority over an outer multiplexer
- **WHEN** the editor runs in a Zellij pane that is itself inside a WezTerm or tmux pane and the user presses a navigation key at the editor's edge
- **THEN** the Zellij backend SHALL be driven and the outer multiplexer SHALL NOT be signalled

#### Scenario: Editor outside any multiplexer
- **WHEN** the user presses a navigation key at the edge of the editor's layout with no multiplexer present
- **THEN** focus SHALL remain unchanged, no multiplexer command SHALL be issued, and no error SHALL be reported

#### Scenario: Failed multiplexer handoff is reported
- **WHEN** a multiplexer focus command is issued and exits with a non-zero status
- **THEN** the system SHALL emit a warning notification identifying the failure, and the editor SHALL remain usable
