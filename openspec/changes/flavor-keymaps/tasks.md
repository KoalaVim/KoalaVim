## 1. Table and engine

- [ ] 1.1 Create `lua/KoalaVim/keymaps/contested.lua` from the audit: hard collisions, prefix rules (`c→v`, `d→r`, `s→f` merge map, `b→q`, `<tab>` drop, Lazy→`z`, profiler→`uP`), D45 vim-default strip list, D46 duplicate list, lazyvim-flavor relocations
- [ ] 1.2 Settle the open lazyvim-flavor keys (black-hole `"_c`/`"_d`, build/deploy, spell hydra, remaining `?` rows) and record them in the table
- [ ] 1.3 Implement `KoalaVim.keymaps.remap`: `keys(plugin, keys)` rewriter (drop / prefix-rewrite / KoalaVim-owned drop), preserving mode/desc/ft/`has`
- [ ] 1.4 Implement the `kmap()` helper for KoalaVim's own keys (skip duplicates and relocate per flavor), and use it for hydra bodies

## 2. LazyVim key sources

- [ ] 2.1 Post-process LazyVim global keymaps on `User LazyVimKeymapsDefaults` (delete stripped/duplicate lhs, re-map relocated ones)
- [ ] 2.2 Add `keys = remap.keys` specs for snacks.nvim, trouble, todo-comments, which-key, nvim-dap, nvim-dap-ui, noice, bufferline, conform, mason, venv-selector, markdown-preview, persistence
- [ ] 2.3 lspconfig `opts` function: apply `remap` to every `opts.servers[*].keys` list (keep `has` gating)
- [ ] 2.4 gitsigns: a single `on_attach` composing LazyVim's maps (lazyvim) or KoalaVim's (koala) plus KoalaVim's non-duplicate maps
- [ ] 2.5 rustaceanvim: wrap `server.on_attach` and remap the buffer-local keys it creates

## 3. KoalaVim key sources

- [ ] 3.1 Convert `config/keymaps/*.lua` to `kmap()` where a key is contested or duplicated
- [ ] 3.2 Convert plugin `keys` in `plugins/*.lua` (pickers, git, ai, coding, editor, debug, lsp) to flavor-aware definitions
- [ ] 3.3 Fix KoalaVim-internal clashes: `<leader>n` CRLF → `<leader>vn`/`<leader>cn`; checkmate `<leader>t*` → `<localleader>t*` in markdown; verify `<RightMouse>`, `<M-z>`, `<M-e>` and AI `<c-h/j/k/l>` are buffer/ft-scoped

## 4. which-key

- [ ] 4.1 which-key `opts` function: filter LazyVim group specs and add KoalaVim groups per flavor (koala: `v r f q z a h uP fN`; lazyvim: LazyVim groups + `a gO uP`)

## 5. Verification

- [ ] 5.1 Implement `KoalaVim.keymaps.check()` (ambiguous-prefix invariant + contested-key winner check), exposed in `:checkhealth KoalaVim`
- [ ] 5.2 Headless test fixture (scratch buffer with gitsigns + an LSP attached) and `make test-keymaps` running both flavors
- [ ] 5.3 Generate a per-flavor keymap cheat sheet (docs) from `contested.lua`
- [ ] 5.4 Manual pass: `<leader>dw`, `<leader>cc`, `<leader>ca(` in koala do black-hole ops; `<leader>vo`, `<leader>rB`, `<leader>fh`, `<leader>qD`, `<leader>zz` work; `H`/`L` are vim defaults
- [ ] 5.5 Manual pass in lazyvim: LazyVim layout intact; `<leader>uv`, `<leader>gv`, `<leader>gV`, `<leader>gn`, `]r`, `]G`, `<M-Up>`, `<M-Left>` reach KoalaVim features; no KoalaVim duplicates in which-key
