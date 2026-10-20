## Why

KoalaVim's completion setup is its most mature feature: fuzzy buffer, path and dictionary sources, agents-skills, filemention, calc, cmp-git, crates, lspkind-priority sorting, filtering out redundant keyword completions, and confirming only an explicitly selected item. It is kept. It now runs on LazyVim's nvim-cmp extra, so it inherits LazyVim's snippet preview/fix helpers, auto-brackets, AI-accept Tab chain and LSP capability registration. Snippets move to the native `vim.snippet` engine with friendly-snippets, which LazyVim uses. Depends on `lazyvim-foundation` (and `lazyvim-lsp-formatting` for the removal of `LSP_CAPS`).

## What Changes

- Enable LazyVim's `coding.nvim-cmp` extra (`vim.g.lazyvim_cmp = "nvim-cmp"`), which disables blink.cmp. KoalaVim's nvim-cmp spec becomes a layer on top of it: KoalaVim's sources, priorities, sorting comparators, mappings, formatting (ofirkai kind icons + lspkind), window style and `preselect = None` replace the extra's. LazyVim's `lazyvim.util.cmp` setup (snippet parse fallback, auto-brackets, missing snippet docs) is kept.
- The `<Tab>` chain is: completion menu next item → snippet forward → AI next-edit/accept (LazyVim's `LazyVim.cmp.map`) → fallback. `<S-Tab>` is: menu previous → snippet backward → fallback. `<CR>` still confirms only an explicitly selected item.
- Cmdline (`/`, `:`) and filetype setups (guihua, dap-repl, dapui_watches, toml/crates, gitcommit/cmp-git) are kept; nvim-cmp also loads on `CmdlineEnter`.
- **BREAKING**: Replace nvim-snippy + cmp-snippy + `ofirgall/vim-snippets` with LazyVim's snippet stack (`garymjr/nvim-snippets` + `rafamadriz/friendly-snippets` + native `vim.snippet`). KoalaVim's `snippets/{c,go,lua,python}.snippets` and the KoalaVim-specific snippets in the `ofirgall/vim-snippets` fork are converted to VSCode-format JSON and shipped from KoalaVim.
- nvim-autopairs (kept, see `lazyvim-ui-editing`) keeps its cmp `confirm_done` hook. It is deduplicated against LazyVim's `auto_brackets` so brackets aren't inserted twice.
- LSP completion capabilities come from the nvim-cmp extra (`vim.lsp.config("*", { capabilities = cmp_nvim_lsp.default_capabilities() })`). KoalaVim's `labelDetailsSupport = nil` tweak moves to `servers["*"].capabilities`.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `autocompletion`: Snippet support moves to native `vim.snippet` with VSCode-format collections, and Tab gains the AI-accept step. The shipped language snippets are converted to VSCode format and supplemented by friendly-snippets.

## Impact

- `lua/KoalaVim/plugins/autocomplete.lua`, `lua/KoalaVim/spec.lua` (extra import), `snippets/` (snipmate → VSCode JSON + `package.json`)
- Removed plugins: `dcampos/nvim-snippy`, `dcampos/cmp-snippy`, `ofirgall/vim-snippets`
- Added: `garymjr/nvim-snippets`, `rafamadriz/friendly-snippets` (through the extra)
- Users with custom snipmate snippets need to convert them to VSCode JSON (or add a snippets search path)
