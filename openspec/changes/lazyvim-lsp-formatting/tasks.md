## 1. Language packs

- [x] 1.1 Import lang extras from `KoalaVim.spec`: clangd, cmake, docker, go, json, markdown, python, rust, typescript, zig
- [x] 1.2 Review each extra's plugin list; disable unwanted additions with `enabled = false` (record what was disabled and why)
- [x] 1.3 Set `vim.g.lazyvim_ts_lsp` from `conf.lsp.tsgo.enabled` before the typescript extra loads; map `conf.lsp.vtsls.max_memory` to vtsls `maxTsServerMemory`

## 2. Server deltas (replace registry)

- [x] 2.1 `servers["*"]`: `on_init` that strips `semanticTokensProvider`; turn off LazyVim native inlay hints (`opts.inlay_hints.enabled = false`)
- [x] 2.2 Rewrite `servers/cpp.lua` as an `opts.servers.clangd` / `cmake` delta (cmd args, WSL `-j=4`, init_options)
- [x] 2.3 Rewrite `servers/python.lua`: pyright settings; ruff (replacing ruff_lsp) with hover off; conform `python = { 'black', 'ruff_format' }`
- [x] 2.4 Rewrite `servers/typescript.lua`: inlay-hint settings for vtsls/tsc; conform `eslint_d`, `prettierd` for TS/JS fts; keep nvim-vtsls if the extra doesn't already provide it
- [x] 2.5 Rewrite `servers/go.lua`: rely on the go extra; go.nvim with `lsp_cfg = false` and no formatter/linter hooks; keep the go buffer-local keys
- [x] 2.6 Rewrite `servers/rust.lua`: move KoalaVim's buffer-local keys into rustaceanvim `server.on_attach` via opts; keep cargo-limit
- [x] 2.7 Rewrite `servers/json.lua`: add the KoalaVim schema (`conf.get_scheme()`) to jsonls schemas via an opts function
- [x] 2.8 Rewrite `servers/markdown.lua`: keep peek, checkmate, render-markdown opts; dedupe markdown-preview with the extra
- [x] 2.9 `servers/misc.lua`/`bash.lua`/`docker.lua`/`zig.lua`/`lua_ls.lua`: plain `servers.bashls`, `servers.vimls`; drop entries the extras/core already cover
- [x] 2.10 Attach navic via `Snacks.util.lsp.on({ method = 'textDocument/documentSymbol' })`; keep navbuddy late-attach and dr-lsp
- [x] 2.11 Remove KoalaVim's `nvim-lspconfig`, `mason.nvim` and `mason-lspconfig` config overrides from `lsp/general.lua`; keep the asdf-shims PATH fix as a mason `opts` function/init hook; keep `:LspServers`/`:Linters`/`:Formatters` aliases

## 3. Formatting

- [x] 3.1 Remove KoalaVim's conform `config`; declare formatters through `opts.formatters_by_ft` and mason `ensure_installed` next to each language
- [x] 3.2 Remove format-on-leave (plugin spec, `utils/lsp.lua` auto_format, `debug.lua` and `utils/git.lua` enable/disable calls)
- [x] 3.3 AutoSave hook: set `vim.b.autoformat = false` before its write and restore the previous value in a one-shot `BufWritePost`
- [x] 3.4 Map `lsp.format.blacklist_ft` (no formatting at all, including forced) and `lsp.autoformat.blacklist_ft` (`vim.b.autoformat = false`) via a FileType autocmd and a guard on the registered formatter
- [x] 3.5 Map `lsp.format.blacklist` / `lsp.autoformat.blacklist` for conform formatters (filter / `condition`) and LSP clients (re-register `LazyVim.lsp.formatter` with KoalaVim's filter)
- [x] 3.6 Point `<leader>F` at `LazyVim.format({ force = true })`; update `config_scheme.jsonc` descriptions for the blacklist keys
- [x] 3.7 Verify rust formatting works through the rust-analyzer LSP fallback

## 4. Linting

- [x] 4.1 Remove none-ls and `NONE_LS_SRCS`; configure nvim-lint `linters_by_ft.python = { 'mypy' }`
- [x] 4.2 Wrap the mypy linter: `--check-untyped-defs`, diagnostics postprocess (import-not-found/import-untyped → INFO + message), run on save

## 5. Diagnostics and LSP UI

- [x] 5.1 Move the diagnostics base config into lspconfig `opts.diagnostics` (KoalaVim signs/icons, underline off, update_in_insert off)
- [x] 5.2 Switch diagnostics-cycle mode 2 to native `virtual_lines`; remove the lsp_lines plugin
- [x] 5.3 Enable the `editor.illuminate` extra and merge KoalaVim's illuminate opts; keep `<C-n>/<C-p>` + `REFRESH_LSP_COUNT()`
- [x] 5.4 Remove lspsaga; re-point `<F2>` → `vim.lsp.buf.rename`, `<F4>` → `vim.lsp.buf.code_action`, `<leader>L` → `vim.diagnostic.open_float`; drop lspsaga hl usage of `ofirkai.design`

## 6. Debugging

- [x] 6.1 Import the `dap.core` extra; layer KoalaVim's dap-ui layout (tab open/close), virtual-text opts, goto-breakpoints
- [x] 6.2 Keep KoalaVim's codelldb / remote gdb / remote delve adapter configs; dedupe the python adapter against nvim-dap-python (keep venv detection)
- [x] 6.3 Keep mason `debugpy` in KoalaVim (corrected: the python extra does not install it; nvim-dap-python needs `debugpy-adapter`)

## 7. Globals cleanup

- [x] 7.1 Remove `LSP_SERVERS`, `LSP_SERVER`, `LSP_CAPS`, `LSP_ON_*`, `LOADED_LSP_SERVERS`, `CONFORM_FORMATTERS`, `NONE_LS_SRCS` from `globals.lua`; update `consts.lua` (null_ls methods)
- [x] 7.2 Add a one-release compatibility shim: writes to the removed globals emit a health warning (and forward `CONFORM_FORMATTERS` to `formatters_by_ft` where feasible)
- [x] 7.3 Remove the `LspServerResolver` type alias; regenerate types

## 8. Verify

- [x] 8.1 For each language (c/cpp, go, python, rust, ts, json, lua, markdown, bash, zig): the server attaches, format on `:w` works, and AutoSave writes don't format
- [x] 8.2 Blacklist knobs: set each of the four in a repo `.kvim.conf` and confirm the behavior from the spec scenarios
- [x] 8.3 mypy missing-import diagnostics show as INFO; semantic tokens absent (`:Inspect`); inlay hints render at EOL
- [x] 8.4 Debug a python test, a rust binary and a C program; the dap-ui tab opens and closes (all three stop at the breakpoint; fixed the tab staying open when the session closes before `terminated`/`exited`)
