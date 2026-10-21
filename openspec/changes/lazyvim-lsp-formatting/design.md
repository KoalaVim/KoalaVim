## Context

Current KoalaVim LSP pipeline (`plugins/lsp/general.lua`, `utils/lsp.lua`, `plugins/globals.lua`):

```
servers/*.lua ──writes──▶ LSP_SERVERS / LSP_SERVER(resolver)      ┐
             ──writes──▶ CONFORM_FORMATTERS / NONE_LS_SRCS          │ globals
lspconfig config(): resolve → LOADED_LSP_SERVERS → vim.lsp.config/enable,
                    mason-lspconfig ensure_installed, LSP_CAPS from cmp_nvim_lsp
conform config():   build formatters_by_ft from CONFORM_FORMATTERS (replaces plugin config)
mason config():     ensure_installed += CONFORM_FORMATTERS + NONE_LS_SRCS
none-ls config():   builtins from NONE_LS_SRCS (formatting forbidden)
format-on-leave → utils.lsp.auto_format → conform.format(async) + bufdo write
```

LazyVim's pipeline: `nvim-lspconfig` `opts.servers` (with `["*"]` defaults, per-server `keys` gated by `has=`, `mason`, `enabled`), an `opts.setup` hook per server, `vim.lsp.config/enable` plus mason-lspconfig auto-enable, `LazyVim.format.register` (conform as primary formatter, LSP as fallback), a BufWritePre autoformat honoring `vim.g.autoformat`/`vim.b.autoformat`, nvim-lint with `linters_by_ft`, and lang extras that bundle all of this per language. LazyVim errors if conform's `config` is replaced.

## Goals / Non-Goals

**Goals:**
- Every server, formatter and linter is configured through LazyVim's opts. No KoalaVim globals for LSP/format/lint.
- KoalaVim keeps its presentation-layer features: the diagnostics cycle, end-of-line inlay hints, illuminate with counts, navic/navbuddy/dr-lsp, and semantic tokens off.
- Existing `kvim.conf` LSP knobs keep working.

**Non-Goals:**
- Which keys trigger LSP actions (LazyVim's `servers["*"].keys` vs KoalaVim's): covered by `flavor-keymaps`. This phase keeps LazyVim's `servers["*"].keys` in place, and KoalaVim's existing LSP keys (`<F2>`, `<F4>`, `<leader>L`, `<leader>F`, `<leader>T`, `<leader>l`) are re-pointed to native or LazyVim functions.
- Completion capabilities (`cmp_nvim_lsp`): the nvim-cmp extra registers them (`lazyvim-completion`).

## Decisions

### D1. Language packs + per-server deltas
Import the lang extras from `KoalaVim.spec` (in the extras slot from `lazyvim-foundation`). Each `servers/<lang>.lua` becomes a `neovim/nvim-lspconfig` spec with an `opts.servers.<name>` delta:
- `cpp.lua`: clangd `cmd` args (`--fallback-style=none`, `--header-insertion=never`, …, `-j=4` on WSL) and `init_options`. The `<leader>n` CRLF map stays (it is a KoalaVim-internal clash, tracked in `flavor-keymaps`).
- `python.lua`: pyright settings. LazyVim's python extra provides `ruff` (replacing `ruff_lsp`); hover on ruff stays off through `opts.setup.ruff` / an on-attach hook. conform: `python = { 'black', 'ruff_format' }`.
- `typescript.lua`: inlay-hint settings for vtsls/tsc, `vim.g.lazyvim_ts_lsp` from `conf.lsp.tsgo.enabled`, `maxTsServerMemory` from `conf.lsp.vtsls.max_memory`. conform keeps `eslint_d`, `prettierd` for TS/JS fts. The `formatting.prettier` / `linting.eslint` extras are not enabled.
- `go.lua`: go extra + go.nvim `lsp_cfg = false`, `lsp_on_attach = false`, no formatter/linter hooks. Drop `CONFORM_FORMATTERS.gofmt` in favor of the extra's goimports/gofumpt.
- `rust.lua`: rustaceanvim from the extra. KoalaVim's buffer-local keys (`<F4>`, `K`, `J`, `<leader>rr/rt`) go into the extra's `server.on_attach` through opts. cargo-limit stays.
- `json.lua`: SchemaStore from the extra. Add the KoalaVim `kvim.conf` schema (`conf.get_scheme()`) to `jsonls.settings.json.schemas` via an opts function.
- `lua_ls.lua`: lazydev comes from LazyVim core; `stylua` comes from LazyVim's conform defaults.
- `markdown.lua`: the extra provides marksman, markdownlint and render-markdown. KoalaVim keeps peek, checkmate and its own render-markdown opts on top. markdown-preview overlaps with the extra and is configured once.
- `misc.lua` / `bash.lua` / `docker.lua` / `zig.lua`: plain `servers.bashls = {}`, `servers.vimls = {}`; the rest comes from the extras.
*Alternative:* port the registry to `opts.servers` without the extras. Rejected because it maintains per-language tooling twice.

### D2. Server-wide defaults via `servers["*"]`
- `on_init`: set `client.server_capabilities.semanticTokensProvider = nil` (this also makes LazyVim's gopls semantic-tokens workaround unnecessary).
- navic attaches through `Snacks.util.lsp.on({ method = 'textDocument/documentSymbol' }, …)`, replacing `LSP_ON_ATTACH`.
- `LSP_ON_ATTACH_NO_HOVER` becomes per-server: `Snacks.util.lsp.on({ name = 'ruff' }, …)` disables hover.

### D3. Formatting: LazyVim format-on-save
- Remove KoalaVim's conform `config`. Formatters come only through `opts.formatters_by_ft`. Mason installs formatters via `mason.nvim` `opts.ensure_installed` (opts_extend), declared next to each formatter.
- `<leader>F` calls `LazyVim.format({ force = true })`. Key placement is finalized in `flavor-keymaps`.
- **AutoSave skips formatting.** `hook_before_actual_saving` sets `vim.b[buf].autoformat = false` and remembers the previous value (nil/true/false). A one-shot buffer `BufWritePost` autocmd restores it. `noautocmd write` was rejected because it would skip gitsigns, LSP didSave and other BufWrite hooks.
- **Blacklists.** `lsp.format.blacklist_ft` sets a FileType autocmd with `vim.b.autoformat = false` and also blocks `LazyVim.format({force})` for those filetypes (wrap the registered conform formatter's `format` with an ft guard). `lsp.autoformat.blacklist_ft` only sets `vim.b.autoformat = false`. `lsp.format.blacklist` / `lsp.autoformat.blacklist` (formatter or LSP client names) work as follows: conform formatters are filtered out of `formatters_by_ft` (format) or skipped with a `condition` that checks an "autoformatting" flag (autoformat). LSP clients are excluded through the filter of `LazyVim.lsp.formatter()` (re-registered with KoalaVim's filter). `dont_format` server flags fold into that same filter.
- Cursor preservation after async format is no longer needed (formatting is synchronous on write).

### D4. Linting: nvim-lint
`linters_by_ft.python = { 'mypy' }`. Wrap `require('lint').linters.mypy` so its parser output is post-processed (import-not-found/import-untyped → INFO with the friendly message) and `args` include `--check-untyped-defs`. Lint events stay LazyVim's (`BufWritePost`, `BufReadPost`, `InsertLeave`). The mypy-specific trigger is on-save only, through the linter `condition`/events, to match today's `DIAGNOSTICS_ON_SAVE`.

### D5. Diagnostics cycle on native backend
`utils/lsp.lua` keeps the three modes. Mode 2 uses `vim.diagnostic.config({ virtual_lines = true })` (Neovim native), and the lsp_lines plugin is removed. The base config (signs with KoalaVim icons, `underline = false`, `update_in_insert = false`, `severity_sort = true`) is set through `opts.diagnostics` on lspconfig, so LazyVim applies it. The cycle overrides only `virtual_text` / `virtual_lines`. diagflow is unchanged.

### D6. LSP UI
- illuminate: enable `editor.illuminate` (disables Snacks.words). KoalaVim opts (`modes_denylist`, `filetypes_denylist`) merge. `<C-n>/<C-p>` with `REFRESH_LSP_COUNT()` stay KoalaVim keys.
- inlay hints: `opts.inlay_hints.enabled = false` on lspconfig. The KoalaVim fork renders hints at end of line.
- lspsaga removed: `<F2>` → `vim.lsp.buf.rename`, `<F4>` → `vim.lsp.buf.code_action`, `<leader>L` → `vim.diagnostic.open_float`. No lightbulb.

### D7. DAP fuse
Enable `dap.core`. KoalaVim's `nvim-dap` spec keeps its adapter configurations for codelldb, remote gdb and remote delve. Python adapters are deduplicated: nvim-dap-python from the python extra handles venv detection, and KoalaVim's own python adapter is removed if dap-python covers it. KoalaVim's dap-ui layout (new tab on start, close on terminate), virtual-text opts and goto-breakpoints are layered on. Remove the format-on-leave enable/disable listeners from `debug.lua` and `utils/git.lua`. mason `debugpy` comes from the python extra.

## Implementation notes (as built)

These corrections came out of implementation and take precedence over the decisions above.

- **D1, language packs:**
  - `vim.g.lazyvim_ts_lsp` is set in `KoalaVim.config.options`. LazyVim's `options.lua` resets it, and it must be set before the extras are imported.
  - The pinned nvim-lspconfig has no `tsc` server, so KoalaVim defines `cmd = { 'tsc', '--lsp', '--stdio' }` and `root_markers` itself. The mason package is `tsc`.
  - The cmake extra uses `neocmake`. KoalaVim's `cmake` server is disabled (`enabled = false`), because mason-lspconfig's `automatic_enable` would otherwise start any stale installed server. ltex is disabled the same way. cmake-tools.nvim is disabled because it regenerates the project on save.
  - go.nvim was already `enabled = false` before this change, so its settings and keys never applied.
  - The rust extra's `config` now runs (KoalaVim's duplicate `default_settings`/`config` are dropped). KoalaVim's rust keys chain after the extra's `on_attach`, and mason installs `rust-analyzer`.
  - The lang extras bring new tooling: golangci-lint (go), markdownlint-cli2 + markdown-toc + prettier formatting (markdown; KoalaVim adds `prettier` to mason because the extra doesn't install it), hadolint (docker), cmakelint (cmake), venv-selector, and clangd_extensions. All are kept.
- **D2, semantic tokens:** the `servers["*"].on_init` strip does **not** cover gopls. LazyVim's gopls workaround re-adds the provider on attach, so gopls also gets `init_options.semanticTokens = false`. No extra sets a per-server `on_init`.
- **D2, navic:** an `init` hook on lspconfig calls `Snacks.util.lsp.on({ method = 'textDocument/documentSymbol' })` from `LazyVim.on_very_lazy`.
- **D3, formatting:**
  - `LazyVim.lsp.formatter()` only accepts a table filter, so it can't exclude clients. Instead, `KoalaVim.utils.lsp.setup_format()` (called from an `init` on the `LazyVim/LazyVim` spec, before any formatter registers) wraps `LazyVim.format.register` and the formatters already registered:
    - Filetype blacklists empty `sources` and turn `format` into a no-op (forced formats included).
    - The LSP formatter's sources and `format` filter clients by the blacklists and `servers[name].dont_format`.
  - "Autoformatting" means a non-forced `LazyVim.format.format` call, which is wrapped to set a flag.
  - Blacklisted conform formatter names get a composed `condition` in conform's `opts.formatters`, rather than being removed from `formatters_by_ft`. This keeps `stop_after_first` and per-filetype lists intact.
  - `gq` (conform's formatexpr) and `<leader>cF` bypass the filetype guard, but still respect `format.blacklist` through the `condition`.
- **D3, AutoSave:**
  - The hook runs its hex and mode guards first.
  - It then stores `vim.b.autoformat` and sets it to false.
  - It restores the stored value in a one-shot `BufWritePost`, plus a scheduled fallback in case the write fails.
- **D4, linting:**
  - mypy runs through `prepend_args = { '--check-untyped-defs' }` and a wrapped parser.
  - "On save only" is implemented as follows. A `BufWritePost` autocmd marks the file, and the linter's `condition` passes once for the marked file.
- **D5, diagnostics:**
  - The base config lives in `plugins/lsp/diagnostics.lua`, an lspconfig opts fragment.
  - Mode 1 is applied on `User LazyLoad` for nvim-lspconfig, via an `init` on diagflow. That event fires after LazyVim calls `vim.diagnostic.config`.
- **D6, illuminate:** KoalaVim's illuminate spec drops its own `config`, so the extra's `config` runs (it adds a Snacks toggle and `]]`/`[[`). The extra's `delay` is 200 ms.
- **D7, DAP:**
  - The nvim-dap spec was `enabled = false` before this change. That is removed.
  - KoalaVim's dap-ui `config` replaces the extra's; lazy.nvim doesn't merge `config`.
  - KoalaVim overrides `LazyVim.config.icons.dap` so the extra keeps KoalaVim's signs.
  - mason-nvim-dap gets no-op handlers for `codelldb` and `cppdbg`, so KoalaVim's adapters aren't replaced.
  - The remote delve adapter is renamed `go_remote`, so it doesn't clobber dap-go's `go`.
  - The python extra does **not** install debugpy (nvim-dap-python needs `debugpy-adapter`), so KoalaVim keeps it in mason `ensure_installed` (task 6.3 premise was wrong).
  - The dap-ui close handler is called on both `terminated` and `exited`. It now tracks the debug tab handle and closes that tab once. The old `tabclose $` raised "E784: Cannot close last tab page", or closed one of your own tabs, when it ran the second time.
  - The handler also runs when the session closes (`dap.listeners.on_session` with no new session). A `disconnect` can close the session before the adapter's `terminated`/`exited` events arrive; those events are then dropped, and the debug tab stayed open in about 1 of 4 runs.
  - On macOS, compile C/C++/Rust through realpaths. lldb matches breakpoint files by the literal path in the debug info, and Neovim resolves symlinks (`/tmp` → `/private/tmp`), so a binary built via `/tmp` never stops. This is not a KoalaVim issue.
- **lazy.nvim `init` is not merged** across spec fragments, so only the last fragment's `init` runs. KoalaVim now owns `init` on `LazyVim/LazyVim` (format policy), `KoalaVim/diagflow.nvim` (initial diagnostics mode), `nvim-dap` and `nvim-lspconfig` (navic). A later phase that adds `init` to any of these must call the existing hook.
- **Lockfile generator:** it now loads only the distribution `default_kvim.conf` into `require('KoalaVim').conf`, because KoalaVim's options read `conf.lsp`, and the developer's own conf must not affect the lockfile.

## Risks / Trade-offs

- [Synchronous format-on-save stalls on slow formatters at `:w`] → Use the `autoformat.blacklist` knobs and `<leader>uf`. AutoSave doesn't format, so this only affects explicit writes.
- [The lang extras pull in plugins KoalaVim didn't have (venv-selector, neotest hooks, markdown-preview duplicates)] → Review each extra's plugin list and disable unwanted ones with `enabled = false` in KoalaVim specs.
- [The rust comment says "rust-analyzer + conform + format-on-leave doesn't work"] → With format-on-save, LazyVim uses rust-analyzer's LSP formatter as fallback. Verify that formatting works and leave conform `rustfmt` unset.
- [Disabling semantic tokens globally removes highlights that some LazyVim lang extras expect] → Accepted (it is KoalaVim's current behavior and needed for ofirkai).
- [User configs writing to removed globals break] → Keep stub globals for one release that emit a health warning and forward to the new opts where possible (e.g. `CONFORM_FORMATTERS[x] = fts` → `formatters_by_ft`).

## Migration Plan

Ship with the other phases. Document the global → opts migration in the changelog, with before/after snippets.

## Open Questions

- Should `ruff` also format (LazyVim's python setup does organize imports via ruff code actions) or only lint? Today ruff formats through conform's `ruff_format` and black also runs. Decide during implementation.
