## MODIFIED Requirements

### Requirement: LSP server configuration registry

The system SHALL provide a global registry for LSP server configurations. Language support modules SHALL register their servers and settings into this registry, and the LSP framework SHALL use it for server initialization. The TypeScript/JavaScript server registration SHALL be conditional based on the `lsp.tsgo.enabled` config flag, registering either tsgo or vtsls.

#### Scenario: Register server
- **WHEN** a language module registers a server with specific settings
- **THEN** the server SHALL be started with those settings when a matching filetype is opened

#### Scenario: Conditional TypeScript server registration
- **WHEN** `lsp.tsgo.enabled` is `true`
- **THEN** the registry SHALL contain `tsgo` and SHALL NOT contain `vtsls`

#### Scenario: Default TypeScript server registration
- **WHEN** `lsp.tsgo.enabled` is `false` or absent
- **THEN** the registry SHALL contain `vtsls` and SHALL NOT contain `tsgo`
