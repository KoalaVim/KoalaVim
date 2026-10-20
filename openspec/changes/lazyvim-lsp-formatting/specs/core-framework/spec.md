## MODIFIED Requirements

### Requirement: Global registries

The system SHALL initialize shared global registries at startup for modal sub-modes, help bindings and ghost filetypes. Components SHALL register into these tables to participate in cross-cutting features. LSP servers, linters and formatters SHALL NOT use global registries. They SHALL be configured through plugin opts.

#### Scenario: Ghost filetype registration
- **WHEN** a component declares a filetype as "ghost" (non-user-content buffer)
- **THEN** that filetype SHALL be excluded from session restoration and buffer-counting logic

#### Scenario: Modal sub-mode registration
- **WHEN** a component registers a hydra definition into the modal sub-modes registry
- **THEN** the sub-mode SHALL be created when the hydra plugin loads

#### Scenario: Removed LSP registries
- **WHEN** a user configuration writes to a removed LSP, linter or formatter global
- **THEN** the system SHALL report a health warning that points to the plugin-opts replacement
