## MODIFIED Requirements

### Requirement: Global registries

The system SHALL initialize shared global registries at startup for LSP servers, linters/formatters, modal sub-modes, formatters, help bindings, and ghost filetypes. Components SHALL register into these tables to participate in cross-cutting features. The LSP servers registry SHALL accept both static opts tables (keyed by server name) and resolver functions (appended via the `LSP_SERVER()` helper). The `LSP_SERVER()` helper SHALL be typed with the `LspServerResolver` alias so that LuaLS can infer the config parameter type inside resolver callbacks.

#### Scenario: LSP server registration
- **WHEN** a language support module loads
- **THEN** it SHALL register its server configuration into the global LSP servers registry

#### Scenario: Ghost filetype registration
- **WHEN** a component declares a filetype as "ghost" (non-user-content buffer)
- **THEN** that filetype SHALL be excluded from session restoration and buffer-counting logic

#### Scenario: Typed LSP resolver registration
- **WHEN** a module calls `LSP_SERVER(function(conf) ... end)`
- **THEN** LuaLS SHALL infer `conf` as `KoalaVim.Conf.lsp` inside the callback

### Requirement: Configuration schema validation

The system SHALL provide a JSON schema describing all configuration keys, their types, and descriptions. Editors with JSON schema support SHALL offer autocompletion and validation for config files. A codegen script (`scripts/gen_conf_types.lua`) SHALL generate LuaLS `---@class` type annotations from the JSON schema into a `---@meta` file, so that Lua code referencing config values receives type checking and autocomplete.

#### Scenario: Schema registered for config files
- **WHEN** a JSON language server is active and the user opens a `.kvim.conf` file
- **THEN** the language server SHALL provide completion and validation using the distribution's schema

#### Scenario: LuaLS types generated from schema
- **WHEN** `make gen-types` is run (or `nvim -l scripts/gen_conf_types.lua`)
- **THEN** the script SHALL read `config_scheme.jsonc` and generate `lua/KoalaVim/types/conf.lua` with `---@class` annotations matching the schema's structure

#### Scenario: Generated types stay in sync
- **WHEN** the JSON schema is modified
- **THEN** re-running the codegen script SHALL produce updated type annotations reflecting the new schema
