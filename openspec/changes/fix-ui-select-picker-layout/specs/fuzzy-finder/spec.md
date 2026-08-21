## MODIFIED Requirements

### Requirement: Picker layout and interaction

All pickers SHALL support toggling the preview pane, navigating results with keyboard shortcuts, and sending results to the diagnostics panel.

The picker framework SHALL define a single project-wide default layout, and individual picker sources SHALL be able to override it with a layout appropriate to their content. A source's layout override SHALL take effect without requiring the override to restate the full window structure.

#### Scenario: Toggle preview
- **WHEN** the user presses the preview-toggle key inside a picker
- **THEN** the preview pane SHALL show or hide

#### Scenario: Send to diagnostics panel
- **WHEN** the user presses the send-to-trouble key inside a picker
- **THEN** all current results SHALL be sent to the diagnostics panel for persistent navigation

#### Scenario: Default layout applies to content pickers
- **WHEN** the user opens a picker that does not declare its own layout (file finder, grep, LSP navigation, diagnostics)
- **THEN** the picker SHALL use the project default layout: a large window with the results list above the search field and a preview pane alongside

#### Scenario: Source-specific layout override takes effect
- **WHEN** a picker source declares a layout override, such as a compact popup for short option lists
- **THEN** the picker SHALL render with that override rather than the project default layout

### Requirement: UI-select routing

The system SHALL route all `vim.ui.select()` calls through the fuzzy picker framework, providing consistent selection UX across all components.

Selection prompts SHALL render as a compact picker sized to the number of options, with no preview pane. The system SHALL NOT display previewer output for selection items, since the items being selected are arbitrary values rather than file locations.

#### Scenario: Component uses vim.ui.select
- **WHEN** any component calls `vim.ui.select()` with a list of options
- **THEN** the fuzzy picker SHALL handle the selection instead of the default prompt

#### Scenario: Selection prompt is compact and preview-less
- **WHEN** a component calls `vim.ui.select()` with a small list of options
- **THEN** the picker SHALL open as a compact popup sized to the option count
- **AND** no preview pane SHALL be shown

#### Scenario: No internal data leaks into the prompt
- **WHEN** the selected option is a table carrying internal state, such as an AI CLI tool entry with its session and process details
- **THEN** the picker SHALL show only the formatted option label
- **AND** SHALL NOT render a dump of the option's underlying data
