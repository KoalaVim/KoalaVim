## Why

The TypeScript compiler has been rewritten in Go (tsgo) by Microsoft, offering 10-25x faster type-checking than the JS-based tsserver that vtsls wraps. tsgo ships a native LSP server (`tsgo --lsp`) that is already in Mason's registry and nvim-lspconfig. While tsgo doesn't yet have full feature parity with vtsls, early adopters should be able to opt in and benefit from the speed improvement on large TypeScript codebases.

## What Changes

- Add a config flag `lsp.tsgo.enabled` (default `false`) to `.kvim.conf` that switches the TypeScript/JavaScript LSP from vtsls to tsgo
- When tsgo is enabled, register `LSP_SERVERS['tsgo']` with the same inlay hints settings currently used for vtsls
- When tsgo is enabled, disable the `nvim-vtsls` wrapper plugin via lazy's `enabled` flag (it provides vtsls-specific commands that don't apply to tsgo)
- Add a health check that warns when `tsgo.enabled = true` but tsgo is not installed
- Mason's `ensure_installed` flow handles tsgo installation automatically when enabled

## Capabilities

### New Capabilities

- `tsgo-lsp`: Opt-in tsgo LSP server support as an alternative to vtsls for TypeScript/JavaScript files

### Modified Capabilities

- `lsp`: The LSP server configuration registry gains a conditional TypeScript server selection based on the tsgo config flag

## Impact

- `lua/KoalaVim/plugins/lsp/servers/typescript.lua` — conditional server registration and nvim-vtsls enabled flag
- `default_kvim.conf` — new `lsp.tsgo` config section
- `config_scheme.jsonc` — schema for `lsp.tsgo`
- `lua/KoalaVim/health.lua` — tsgo availability health check
- No breaking changes — default behavior is unchanged (vtsls remains the default)
