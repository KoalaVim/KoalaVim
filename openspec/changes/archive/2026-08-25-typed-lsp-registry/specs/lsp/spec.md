## MODIFIED Requirements

### Requirement: LSP server configuration registry

The system SHALL provide a global registry (`LSP_SERVERS`) for LSP server configurations. Language support modules SHALL register their servers into this registry either as static opts tables keyed by server name, or as resolver functions via the `LSP_SERVER()` helper. Resolver functions SHALL receive the typed LSP config (`KoalaVim.Conf.lsp`) and return a server name and opts table. The LSP framework SHALL resolve all entries and use them for server initialization.

#### Scenario: Register server with static opts
- **WHEN** a language module assigns `LSP_SERVERS['<name>'] = { opts }` at load time
- **THEN** the server SHALL be started with those settings when a matching filetype is opened

#### Scenario: Register server with resolver function
- **WHEN** a language module calls `LSP_SERVER(function(conf) return name, opts end)`
- **THEN** the resolver SHALL be called during LSP initialization with the LSP config, and the returned server SHALL be registered and started

#### Scenario: Resolver receives typed config
- **WHEN** a resolver function is invoked
- **THEN** it SHALL receive the `conf.lsp` table so it can make config-dependent decisions (e.g., choosing between `tsgo` and `vtsls`)

#### Scenario: Resolver skips registration
- **WHEN** a resolver function returns `nil`
- **THEN** no server SHALL be registered for that resolver

#### Scenario: Resolved servers available at runtime
- **WHEN** all resolvers have been called during initialization
- **THEN** the global `LSP_SERVERS` table SHALL contain the resolved name-to-opts mapping, accessible to runtime code
