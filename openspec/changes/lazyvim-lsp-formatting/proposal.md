## Why

KoalaVim's LSP layer is built on hand-rolled global registries (`LSP_SERVERS`, `LSP_SERVER()`, `LSP_CAPS`, `LSP_ON_*`, `CONFORM_FORMATTERS`, `NONE_LS_SRCS`), which already carry a TODO asking for a better solution. LazyVim offers a mergeable `opts.servers` registry, capability-gated per-server keys, mason auto-install, `LazyVim.format` with toggles, nvim-lint, and maintained language packs (LSP, formatter, linter, treesitter and debugger per language). KoalaVim's strengths are on the presentation side: the diagnostics display cycle, end-of-line inlay hints, reference highlighting with counts, and symbol navigation. Those stay. Depends on `lazyvim-foundation`.

## What Changes

- **BREAKING**: Remove the `LSP_SERVERS` / `LSP_SERVER()` / `LSP_CAPS` / `LSP_ON_INIT` / `LSP_ON_ATTACH*` / `LOADED_LSP_SERVERS` / `CONFORM_FORMATTERS` / `NONE_LS_SRCS` globals. Servers are configured through LazyVim's `nvim-lspconfig` `opts.servers`, and formatters through conform's `formatters_by_ft`.
- Enable LazyVim language extras: `lang.clangd`, `lang.cmake`, `lang.docker`, `lang.go`, `lang.json`, `lang.markdown`, `lang.python`, `lang.rust`, `lang.typescript`, `lang.zig`. KoalaVim's per-server files shrink to `opts.servers[x]` overrides; `bashls` and `vimls` are added as plain servers.
- `kvim.conf` `lsp.tsgo.enabled` maps to `vim.g.lazyvim_ts_lsp = "tsc"`, and `lsp.vtsls.max_memory` maps to a vtsls settings override.
- Python: `ruff_lsp` → `ruff` (LazyVim's default). KoalaVim keeps black + ruff_format through conform.
- Go: LazyVim's go extra owns gopls/gofumpt/goimports/dap-go. go.nvim stays for its commands only (`lsp_cfg = false`).
- **BREAKING**: Formatting moves to LazyVim's format-on-save (`LazyVim.format` + conform, `<leader>uf`/`<leader>uF` toggles, `vim.g/b.autoformat`). format-on-leave is removed. AutoSave's own writes skip formatting. The `kvim.conf` `lsp.format.*` / `lsp.autoformat.*` blacklists are kept and mapped onto LazyVim's mechanisms.
- Linting moves from none-ls to nvim-lint. mypy keeps its import-not-found → INFO postprocess and `--check-untyped-defs`.
- Diagnostics: KoalaVim's 3-mode cycle (flow / virtual lines / errors-only) stays, built on LazyVim's `opts.diagnostics`. The `lsp_lines` plugin is replaced by native `virtual_lines`.
- LSP UI: keep vim-illuminate (through LazyVim's `editor.illuminate` extra) with the dr-lsp counter, the inlay-hints end-of-line fork (LazyVim's native inlay hints turned off), semantic tokens disabled for all servers, and navic/navbuddy/dr-lsp. **BREAKING**: remove lspsaga, so rename, code action and line diagnostics use the native UI and the lightbulb sign is gone.
- Debugging: enable LazyVim's `dap.core` extra (debugger installs, extra controls, lang-extra debug hooks). KoalaVim's dap-ui layout, virtual text, goto-breakpoints and adapters are layered on top.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `lsp`: The server registry is replaced by LazyVim opts and language packs. Formatting moves to format-on-save with blacklists mapped to LazyVim. Linting via nvim-lint, semantic tokens off, end-of-line inlay hints and reference highlighting are added.
- `core-framework`: The global registries lose the LSP server, linter/formatter and formatter tables.
- `editor-enhancements`: Automatic file saving no longer triggers formatting.
- `debugging`: The format-on-leave requirement is removed. LazyVim's extra debug controls are added.

## Impact

- `lua/KoalaVim/plugins/lsp/general.lua`, `lua/KoalaVim/plugins/lsp/servers/*.lua`, `lua/KoalaVim/utils/lsp.lua`, `lua/KoalaVim/plugins/globals.lua`, `lua/KoalaVim/consts.lua`
- `lua/KoalaVim/plugins/debug.lua`, `lua/KoalaVim/plugins/editor.lua` (AutoSave), `lua/KoalaVim/spec.lua` (extras imports)
- `lua/KoalaVim/plugins/ui.lua` (lualine LSP status / dr-lsp counts if they read `LOADED_LSP_SERVERS`)
- Removed plugins: `nvimtools/none-ls.nvim`, `ofirgall/format-on-leave.nvim`, `glepnir/lspsaga.nvim`, `ofirgall/lsp_lines.nvim`, `mhanberg/output-panel.nvim` (already disabled)
- Added: LazyVim lang extras and their plugins (SchemaStore, rustaceanvim, crates, venv-selector, nvim-dap-python, dap-go, markdown tools, etc.), `mfussenegger/nvim-lint`
- User configs that write to `LSP_SERVERS` / `CONFORM_FORMATTERS` / `NONE_LS_SRCS` need to switch to `opts.servers` / `formatters_by_ft` / `linters_by_ft`
