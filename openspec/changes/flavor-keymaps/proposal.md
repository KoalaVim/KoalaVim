## Why

Once KoalaVim layers on LazyVim, two complete keymap layouts are active at the same time. A static audit found 30 exact-key collisions and 9 prefix collisions. In the prefix collisions a KoalaVim single key sits on a LazyVim group prefix, and with `timeoutlen=300` the group key gets hijacked: `<leader>dw` (delete word, no yank) would open DAP widgets, `<leader>cc` (change line) would run codelens, and the `<leader>s` spell hydra would take over the whole search group. LazyVim also overrides vim defaults that KoalaVim users rely on, and both sides bind the same actions to different keys. This change resolves all of it with the global `flavor`. Depends on all previous phases.

## What Changes

- A data-driven contested-keys table: every contested key resolves to exactly one action per flavor.
- **koala flavor** (default):
  - KoalaVim keys win every collision.
  - LazyVim's colliding groups move: code `<leader>c*` → `<leader>v*` (including lang-extra and LSP keys), debug `<leader>d*` → `<leader>r*` (joining KoalaVim's `rc`/`rp`), search `<leader>s*` merged into `<leader>f*`, buffer `<leader>b*` → `<leader>q*`. Tab keys `<leader><tab>*` are dropped. Lazy goes to `<leader>zz`, LazyVim changelog to `<leader>zl`, LazyExtras to `<leader>zx`. The profiler goes to `<leader>uP*`.
  - LazyVim's overrides of vim defaults are removed (`H`/`L`, `<A-j/k>`, `<C-s>`, `<esc>` nohl, insert undo-breakpoints, x-mode `<`/`>`, `gco`/`gcO`, `[b ]b [B ]B`, `]] [[`, `gy`, `gK`, `<leader>-`/`<leader>|`).
  - LazyVim bindings that duplicate a KoalaVim action under a different key are removed.
- **lazyvim flavor**: LazyVim's layout wins every collision. KoalaVim keys for features LazyVim lacks stay. KoalaVim keys that only repeat a LazyVim action are dropped. Displaced KoalaVim features get new keys (e.g. diagnostics cycle `<leader>uv`, codediff `<leader>gv`, diff hydra `<leader>gV`, neogit `<leader>gn`, push `<leader>gu/gU`, octo `<leader>gO*`, multi-cursor `<M-Up/Down>`, sibling-swap `<M-Left/Right>`, dirty-file jump `]G/[G`, breakpoint jump `]r/[r`, FeMaco `<leader>cE`).
- which-key group labels are generated per flavor (no `gs = surround` label, no labels for relocated groups).
- An invariant check (health and a headless test): within each mode, no key is both a complete mapping and a prefix of another mapping in the leader namespace, and every contested key resolves to its flavor's winner.
- KoalaVim-internal clashes are fixed: `<leader>n` (c/cpp CRLF vs notification history), `<leader>t` (Trouble vs checkmate prefix), `<RightMouse>` (hover vs debug), `<M-z>` (AI vs NeoZoom), `<M-e>` (vsplit vs terminal), and `<c-h/j/k/l>` in AI buffers vs Navigator.

## Capabilities

### New Capabilities
- `keymap-flavors`: Contested-key resolution per flavor, koala-flavor relocation of LazyVim groups, removal of duplicates and vim-default overrides, lazyvim-flavor homes for KoalaVim features, flavor-specific which-key groups, and the no-ambiguous-prefix invariant.

### Modified Capabilities
- `navigation`: Arrow-key scrolling and search auto-centering become koala-flavor behaviors. Black-hole delete/change and deploy stay available in both flavors, on flavor-specific keys.

## Impact

- New: `lua/KoalaVim/keymaps/contested.lua` (table), `lua/KoalaVim/keymaps/remap.lua` (spec `keys` rewriter, global-keymap post-processor), `lua/KoalaVim/keymaps/check.lua` (invariant), health entries
- KoalaVim spec overrides with `keys = function(_, keys)` for: snacks.nvim, trouble, todo-comments, which-key, nvim-dap / nvim-dap-ui, noice, bufferline, conform, mason, venv-selector, markdown-preview, gitsigns (`on_attach` composition), nvim-lspconfig (`opts.servers[*].keys`), rustaceanvim (`server.on_attach` keys), persistence
- `lua/KoalaVim/config/keymaps/*`, `lua/KoalaVim/plugins/*` (KoalaVim key definitions become flavor-aware)
- Docs: keymap reference per flavor
