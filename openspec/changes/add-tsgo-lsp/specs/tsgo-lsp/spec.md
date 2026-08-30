## ADDED Requirements

### Requirement: Opt-in tsgo LSP server

The system SHALL support tsgo as an alternative TypeScript/JavaScript LSP server, activated by setting `lsp.tsgo.enabled` to `true` in `.kvim.conf`. When enabled, tsgo SHALL fully replace vtsls for all TS/JS filetypes. When disabled (default), vtsls SHALL remain the active server with no behavioral changes.

#### Scenario: tsgo enabled
- **WHEN** `lsp.tsgo.enabled` is `true` in `.kvim.conf`
- **THEN** the system SHALL register `tsgo` as the LSP server for typescript, typescriptreact, javascript, and javascriptreact filetypes

#### Scenario: tsgo disabled (default)
- **WHEN** `lsp.tsgo.enabled` is `false` or absent in `.kvim.conf`
- **THEN** the system SHALL register `vtsls` as the LSP server (unchanged default behavior)

#### Scenario: Only one TS server active
- **WHEN** `lsp.tsgo.enabled` is `true`
- **THEN** the system SHALL NOT register vtsls as an LSP server (nvim-vtsls plugin remains loaded but inactive)

### Requirement: tsgo inlay hints

The system SHALL configure tsgo with the same inlay hints settings used for vtsls, including parameterNames, parameterTypes, variableTypes, propertyDeclarationTypes, functionLikeReturnTypes, and enumMemberValues.

#### Scenario: Inlay hints with tsgo
- **WHEN** tsgo is the active LSP server
- **THEN** inlay hints SHALL be configured with the same settings as the vtsls configuration

### Requirement: tsgo Mason installation

The system SHALL include tsgo in Mason's `ensure_installed` list when `lsp.tsgo.enabled` is `true`. The existing Mason auto-install flow SHALL handle tsgo installation.

#### Scenario: Auto-install tsgo
- **WHEN** `lsp.tsgo.enabled` is `true` and tsgo is not installed
- **THEN** Mason SHALL automatically install tsgo via the `@typescript/native-preview` npm package

### Requirement: tsgo health check

The system SHALL include a health check that reports a warning when `lsp.tsgo.enabled` is `true` but the `tsgo` executable is not available.

#### Scenario: tsgo enabled but not installed
- **WHEN** `lsp.tsgo.enabled` is `true` and `tsgo` is not executable
- **THEN** `:checkhealth` SHALL display a warning indicating tsgo is not installed

#### Scenario: tsgo enabled and installed
- **WHEN** `lsp.tsgo.enabled` is `true` and `tsgo` is executable
- **THEN** `:checkhealth` SHALL display an OK status for tsgo

### Requirement: tsgo config schema

The `.kvim.conf` JSON schema SHALL include the `lsp.tsgo` section with an `enabled` boolean property. The `default_kvim.conf` SHALL set `lsp.tsgo.enabled` to `false`.

#### Scenario: Config schema validation
- **WHEN** a user sets `lsp.tsgo.enabled` to a non-boolean value
- **THEN** the JSON schema SHALL flag a validation error
