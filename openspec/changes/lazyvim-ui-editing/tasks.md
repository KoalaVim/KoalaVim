## 1. Disable LazyVim duplicates

- [ ] 1.1 `enabled = false` specs for `folke/flash.nvim`, `nvim-mini/mini.pairs`, `folke/ts-comments.nvim`, `MagicDuck/grug-far.nvim`
- [ ] 1.2 Turn off the snacks explorer (`vim.g.lazyvim_explorer` / disable the default `editor.snacks_explorer` extra); keep nvim-tree with its node actions
- [ ] 1.3 snacks opts: `indent`, `scope`, `input`, `words` disabled; confirm statuscol.nvim's `statuscolumn` wins over LazyVim's `options.lua`
- [ ] 1.4 Don't enable `coding.yanky`, `ui.smear-cursor`, `editor.mini-move`, `editor.dial`, `ui.treesitter-context`; keep KoalaVim's specs

## 2. Flavor gating

- [ ] 2.1 lualine/bufferline: KoalaVim spec picks opts with `flavor.pick` (koala → ofirkai statusline/tabline + KoalaVim components; lazyvim → LazyVim opts + ofirkai theme)
- [ ] 2.2 Dashboard: alpha `enabled` only for koala; snacks `dashboard.enabled` only for lazyvim; append KoalaVim buttons (AI, git diff, update, changelog) to the snacks dashboard keys
- [ ] 2.3 Add the `User KoalaDashboardClosed` event (alpha close hook / snacks dashboard buffer hide); switch `CLOSE_KOALA_DASHBOARD` and koala modes off `AlphaClosed`
- [ ] 2.4 Sessions: possession `enabled` koala-only, persistence lazyvim-only; refactor `utils/session.lua` into an adapter (save/load_cwd/delete_cwd/exists_cwd/list + pre-save/post-load hooks); persistence implementation with a sidecar JSON for component state
- [ ] 2.5 Route session disable controls (`KOALA_NO_SESSION`, single-file, AI/git modes) and restart auto-load through the adapter
- [ ] 2.6 Terminal: toggleterm + term-edit for koala; snacks terminal for lazyvim; keep term-edit and terminal escape in both

## 3. Fused plugins

- [ ] 3.1 Picker routing: after `LazyVim.pick` registers snacks, wrap `picker.open` to send `files` → fff and `live_grep`/`grep` → fff (honoring `cwd`/`root=false`), everything else → snacks
- [ ] 3.2 noice: `opts` function merging `misc/noice_routes.lua` into LazyVim's; keep `KOALA_NO_NOICE`, hover/signature borders and scroll keys; `lsp.progress.enabled = false`
- [ ] 3.3 gitsigns: `opts` function on top of LazyVim's (signs) with KoalaVim settings; keep KoalaVim's `on_attach` until `flavor-keymaps`

## 4. Swaps to LazyVim

- [ ] 4.1 Trouble: remove the `ofirgall/trouble.nvim` fork; port `hydras/helpers/trouble.lua` and `<leader>t` (buffer diagnostics) to the v3 API
- [ ] 4.2 mini.ai: remove KoalaVim's spec; resolve textobject key overlaps with various-textobjs

## 5. Verify

- [ ] 5.1 Start with `flavor = "koala"` and with `"lazyvim"`: no errors, the expected plugin set is loaded (`:Lazy` loaded list), and each concern has exactly one owner
- [ ] 5.2 lazyvim flavor: the snacks dashboard shows KoalaVim buttons; persistence auto-loads; component hooks (build/debug targets) survive a restart; snacks terminal toggles
- [ ] 5.3 koala flavor: alpha, possession named sessions, toggleterm toggle-all/split unchanged
- [ ] 5.4 `LazyVim.pick('files')`, `LazyVim.pick('live_grep')` and `LazyVim.pick('oldfiles')` open fff, fff and snacks respectively
- [ ] 5.5 Startup modes (git/ai/diff) work in both flavors
