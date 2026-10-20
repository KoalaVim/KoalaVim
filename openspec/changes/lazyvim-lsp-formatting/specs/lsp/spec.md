## ADDED Requirements

### Requirement: LSP server configuration through plugin opts

LSP servers SHALL be configured through LazyVim's `nvim-lspconfig` `opts.servers` table, merged across LazyVim, its language extras, KoalaVim and the user. Server-wide defaults SHALL be set through the `"*"` entry. A server SHALL be disableable with `enabled = false`, and SHALL be excludable from automatic installation with `mason = false`.

#### Scenario: KoalaVim overrides a language-extra server setting
- **WHEN** a LazyVim language extra configures a server and KoalaVim sets additional settings for the same server
- **THEN** the server SHALL start with the merged settings, KoalaVim's values taking precedence

#### Scenario: User disables a server
- **WHEN** the user sets `opts.servers.<name> = { enabled = false }` in their plugin specs
- **THEN** that server SHALL NOT be started or installed

#### Scenario: Server-wide default applied
- **WHEN** a setting is placed in `opts.servers["*"]`
- **THEN** every configured server SHALL receive that setting

### Requirement: Language packs

Language support for C/C++, CMake, Docker, Go, JSON, Markdown, Python, Rust, TypeScript/JavaScript and Zig SHALL come from LazyVim's language extras. Each extra provides the language server, formatter, linter, treesitter parsers and debugger integration. KoalaVim SHALL apply its per-language adjustments on top. The TypeScript server SHALL be selectable between vtsls and tsc/tsgo via `lsp.tsgo.enabled`, and `lsp.vtsls.max_memory` SHALL set the TypeScript server memory limit.

#### Scenario: tsgo enabled in config
- **WHEN** `lsp.tsgo.enabled` is `true` in the merged configuration
- **THEN** the tsc/tsgo language server SHALL be used for TypeScript and JavaScript instead of vtsls

#### Scenario: Python tooling
- **WHEN** a Python file is opened
- **THEN** pyright and ruff SHALL attach, and the file SHALL be formatted with black and ruff_format on save

#### Scenario: KoalaVim config schema in JSON server
- **WHEN** the user opens a `.kvim.conf` file
- **THEN** the JSON language server SHALL validate it against the KoalaVim schema, in addition to SchemaStore schemas for other files

### Requirement: Linting

Linters SHALL run through nvim-lint, configured per filetype. For Python, mypy SHALL run on save with `--check-untyped-defs`. Its missing-import diagnostics (`import-not-found`, `import-untyped`) SHALL be downgraded to INFO severity with an explanatory message.

#### Scenario: Missing stubs downgraded
- **WHEN** mypy reports `import-not-found` for an import in a Python file
- **THEN** the diagnostic SHALL appear with INFO severity and a message explaining missing library stubs

### Requirement: Semantic tokens disabled

The system SHALL disable LSP semantic token highlighting for all servers, so that treesitter and the color scheme control highlighting.

#### Scenario: Server offers semantic tokens
- **WHEN** a language server that supports semantic tokens attaches
- **THEN** no semantic token highlights SHALL be applied to the buffer

### Requirement: End-of-line inlay hints

The system SHALL render LSP inlay hints (parameter names and types) as virtual text at the end of the line rather than inline, and SHALL provide a toggle. The native inline inlay hints SHALL be disabled.

#### Scenario: Show parameter hints
- **WHEN** inlay hints are enabled and a line contains a call with parameter hints
- **THEN** the hints SHALL appear after the end of that line

### Requirement: Reference highlighting and navigation

The system SHALL highlight other occurrences of the symbol under the cursor (outside insert mode and excluded filetypes). It SHALL also provide next/previous-reference jumps that wrap around and update a reference/definition counter.

#### Scenario: Jump to next reference
- **WHEN** the cursor is on a symbol with several references and the user triggers next-reference
- **THEN** the cursor SHALL move to the next reference (wrapping at the end) and the reference counter SHALL update

## MODIFIED Requirements

### Requirement: Formatting with blacklists

The system SHALL format code with dedicated formatters through LazyVim's formatting pipeline, falling back to LSP formatting. Both format-on-demand and auto-format-on-save SHALL be supported. Auto-format SHALL be toggleable globally and per buffer. The configurable blacklists SHALL continue to work: `lsp.format.blacklist` / `lsp.format.blacklist_ft` exclude formatters, LSP clients or filetypes from all formatting, and `lsp.autoformat.blacklist` / `lsp.autoformat.blacklist_ft` exclude them from auto-format-on-save only.

#### Scenario: Auto-format on save
- **WHEN** a file is saved explicitly and auto-format is enabled for its buffer and filetype
- **THEN** the file SHALL be formatted using the configured formatter (or LSP fallback) before it is written

#### Scenario: Formatter blacklisted
- **WHEN** a formatter is on the format blacklist for the current filetype
- **THEN** that formatter SHALL not be used, and the system SHALL fall back to the next available formatter

#### Scenario: Filetype blacklisted
- **WHEN** the current file's type is on the auto-format filetype blacklist
- **THEN** auto-format-on-save SHALL be skipped for this file, while format-on-demand SHALL still work

#### Scenario: Filetype blacklisted for all formatting
- **WHEN** the current file's type is on the format filetype blacklist
- **THEN** neither auto-format nor format-on-demand SHALL modify the file

#### Scenario: Toggle auto-format
- **WHEN** the user toggles auto-format off for the current buffer
- **THEN** saving that buffer SHALL NOT format it until auto-format is toggled back on

## REMOVED Requirements

### Requirement: LSP server configuration registry
**Reason**: The `LSP_SERVERS` global registry and `LSP_SERVER()` resolvers are replaced by LazyVim's mergeable `opts.servers` and its language extras.
**Migration**: Replace `LSP_SERVERS['<name>'] = opts` with a `neovim/nvim-lspconfig` spec setting `opts.servers['<name>'] = opts`. Replace config-dependent resolvers with an `opts` function that reads `require('KoalaVim').conf`, or with the corresponding `vim.g.lazyvim_*` variable.
