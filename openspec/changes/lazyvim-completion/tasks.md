## 1. Extra and spec layering

- [x] 1.1 Set `vim.g.lazyvim_cmp = "nvim-cmp"` and import the `coding.nvim-cmp` extra from `KoalaVim.spec`
- [x] 1.2 Convert KoalaVim's nvim-cmp spec to `opts = function(_, opts)` that replaces mapping/sources/sorting/formatting/window/preselect/completeopt and clears `auto_brackets`
- [x] 1.3 Add `config = function(_, opts)` calling `require('lazyvim.util.cmp').setup(opts)`, then lspkind-priority setup, cmdline `/` and `:` setups, filetype setups (guihua, guihua_rust) and the autopairs `confirm_done` hook
- [x] 1.4 Set `event = { 'InsertEnter', 'CmdlineEnter' }`; keep KoalaVim's source dependency list (fuzzy-buffer/path/dictionary, agents-skills, calc, filemention, cmdline)

## 2. Mappings

- [x] 2.1 Implement the `<Tab>` chain: menu next → `LazyVim.cmp.map({ 'snippet_forward', 'ai_nes', 'ai_accept' }, fallback)` (modes i, c)
- [x] 2.2 Implement `<S-Tab>`: menu prev → `vim.snippet.jump(-1)` when active → fallback
- [x] 2.3 Keep `<CR>` explicit-selection confirm, `<C-Space>`, `<C-n>/<C-p>`, doc scroll `<C-u>/<C-d>/<C-y>/<C-e>`

## 3. Snippets

- [x] 3.1 Remove nvim-snippy, cmp-snippy and vim-snippets specs; switch the cmp source `snippy` → `snippets` (priority 200)
- [x] 3.2 Convert `snippets/{c,go,lua,python}.snippets` to VSCode JSON plus `snippets/package.json`; add KoalaVim's `snippets/` to nvim-snippets `search_paths`
- [x] 3.3 Diff `ofirgall/vim-snippets` against honza upstream; convert the KoalaVim-specific snippets into the same JSON files
- [x] 3.4 Rewrite snippets that use snipmate interpolation / `${VISUAL}` (list them in the PR)

## 4. Capabilities

- [x] 4.1 Remove `LSP_CAPS` construction; move the `labelDetailsSupport = nil` tweak to lspconfig `servers["*"].capabilities`; verify the merged `vim.lsp.config["*"]`

## 5. Verify

- [x] 5.1 Source priority order unchanged (LSP > filemention > fuzzy_path > agents_skills > snippets > buffers > dictionary/calc)
- [x] 5.2 Redundant keyword/text LSP items still filtered; `<CR>` without selection inserts a newline
- [x] 5.3 Snippet expand plus Tab/S-Tab placeholder navigation in go, python, lua, c
- [x] 5.4 Python function completion inserts `()` exactly once
- [x] 5.5 Cmdline `/` and `:` completion; cmp-git in gitcommit; crates in Cargo.toml; dap-repl completion
