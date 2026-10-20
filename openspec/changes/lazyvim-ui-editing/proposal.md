## Why

With the foundation in place, each overlapping plugin must have exactly one owner. For every UI or editing concern, either KoalaVim's or LazyVim's plugin wins, or the two are fused. A few areas switch with the `flavor` setting, so a lazyvim-flavor user gets LazyVim's experience while keeping KoalaVim's unique features. Depends on `lazyvim-foundation`.

## What Changes

- **KoalaVim wins** (LazyVim's equivalent is disabled): nvim-tree (snacks explorer off), leap + flit (flash off), nvim-autopairs (mini.pairs off), Comment.nvim + ts-context-commentstring (ts-comments off), nvim-surround, spectre + muren (grug-far off), indent-blankline, statuscol.nvim and dressing (snacks indent/scope/statuscolumn/input off), fidget for LSP progress, navic/navbuddy/dr-lsp, and KoalaVim's own specs for yanky, smear-cursor, move.nvim, nvim-toggler and treesitter-context (the matching LazyVim extras are not enabled).
- **LazyVim wins**: trouble v3. **BREAKING**: KoalaVim's v2 fork is dropped, and the hydra trouble helper is ported to v3. mini.ai: LazyVim's custom textobjects (function, class, block, tag, digits, case-word, buffer, usage), with KoalaVim's various-textobjs and TS textobjects kept.
- **Fused**:
  - picker: fff stays the file finder and live grep, and the snacks picker with KoalaVim's layout handles everything else. Both are reached through `LazyVim.pick`, so LazyVim's picker calls (core and lang extras) route to fff for files/grep.
  - noice: LazyVim's opts plus KoalaVim's routes, with noice LSP progress off because fidget owns it.
  - gitsigns: LazyVim's opts base plus KoalaVim's config; key placement is handled in `flavor-keymaps`.
- **Flavor-driven** (`flavor = "koala"` → KoalaVim, `"lazyvim"` → LazyVim):
  - statusline and bufferline: KoalaVim's ofirkai lualine/bufferline, or LazyVim's lualine/bufferline with the ofirkai theme
  - dashboard: alpha fork, or snacks dashboard
  - sessions: possession, or persistence
  - terminal: toggleterm + term-edit, or snacks terminal
- Dashboard-close and session hooks that assume alpha/possession are replaced by backend-neutral KoalaVim events and a small session adapter. Startup modes and component state hooks then work in both flavors.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `ui`: The status line, buffer line and dashboard become flavor-dependent.
- `sessions`: The session backend follows the flavor. Named sessions are available only with the koala flavor. Component hooks work in both through an adapter.
- `terminal`: The terminal backend follows the flavor. Toggle-all, multi-instance and terminal splitting are available only with the koala flavor.
- `code-editing`: Extended text objects gain LazyVim's mini.ai objects.
- `fuzzy-finder`: Adds picker routing so LazyVim callers open KoalaVim's file finder and grep.

## Impact

- `lua/KoalaVim/plugins/{ui,editor,coding,pickers,sessions,terminal,git}.lua`, `lua/KoalaVim/plugins/hydra/hydras/helpers/trouble.lua`, `lua/KoalaVim/misc/noice_routes.lua`, `lua/KoalaVim/utils/{session,restore,modes}.lua`
- Disabled LazyVim plugins: flash, mini.pairs, ts-comments, grug-far; snacks explorer/indent/scope/statuscolumn/input/words modules
- Flavor-gated: alpha / snacks dashboard, possession / persistence, toggleterm+term-edit / snacks terminal, KoalaVim / LazyVim lualine+bufferline opts
- Removed: `ofirgall/trouble.nvim` fork (v2) → `folke/trouble.nvim` v3; the `echasnovski/mini.ai` repo name → `nvim-mini/mini.ai`
- ofirkai: snacks dashboard and trouble v3 highlights (tracked in `lazyvim-foundation`)
