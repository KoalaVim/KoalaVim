## Context

After `lazyvim-foundation`, LazyVim's core plugin specs are all active alongside KoalaVim's. LazyVim core brings flash, mini.pairs, ts-comments, mini.ai, grug-far, trouble, todo-comments, gitsigns, which-key, bufferline, lualine, noice, mini.icons and persistence. Its default extras bring the snacks picker and snacks explorer, and LazyVim's snacks opts enable dashboard, indent, input, scope, scroll, statuscolumn (via options), words and terminal. This change gives each overlap a single owner and makes four areas flavor-dependent.

## Goals / Non-Goals

**Goals:** Exactly one active plugin per concern. Flavor switching for statusline/bufferline, dashboard, sessions and terminal. KoalaVim features reachable in both flavors.

**Non-Goals:** Keymap reconciliation and which-key groups, which belong to `flavor-keymaps`. Plugin keys introduced here use their current KoalaVim or LazyVim keys and are reconciled there.

## Decisions

### D1. Disabling LazyVim plugins
Use `{ '<repo>', enabled = false }` specs in KoalaVim for flash, mini.pairs, ts-comments and grug-far. For the snacks modules, use opts (`indent`, `scope`, `input`, `words`, `explorer` = `enabled = false`). Set `vim.opt.statuscolumn` from statuscol.nvim, which runs after LazyVim's `options.lua` sets it. For the explorer, set `vim.g.lazyvim_explorer`, or turn off the default `editor.snacks_explorer` extra with an `enabled = false` spec on its import if needed. LazyVim's internal checks (`LazyVim.has("flash.nvim")` and similar) degrade gracefully.

### D2. Flavor gating pattern
Each flavor-dependent pair uses `enabled = function() return require('KoalaVim.flavor').is('koala') end` on the KoalaVim-side plugin and the opposite on the LazyVim-side plugin. `cond` is avoided because it keeps plugins installed but unloaded and can confuse the lockfile. Where both flavors use the same plugin (lualine, bufferline), KoalaVim's spec chooses its opts with `flavor.pick({ koala = koala_opts, lazyvim = function(_, opts) <ofirkai theme tweak> end })`. snacks `dashboard.enabled` and `terminal` usage are set the same way.

### D3. Backend-neutral events and session adapter
- Dashboard: add `User KoalaDashboardClosed`, fired by alpha's close hook (koala flavor) and by a snacks dashboard `BufWipeout`/`BufHidden` autocmd (lazyvim flavor). `CLOSE_KOALA_DASHBOARD` and koala modes use it in place of `AlphaClosed`.
- Sessions: `KoalaVim.utils.session` becomes an adapter with `save()`, `load_cwd()`, `delete_cwd()`, `exists_cwd()`, `list()`, and `on_pre_save` / `on_post_load` hook registration. The possession implementation is today's code. The persistence implementation maps to `persistence.save/load/stop/select` and its `PersistenceSavePre` / `PersistenceLoadPost` events. Component state (build/debug/deploy) is stored in a sidecar JSON keyed by the session file. Named sessions are possession-only.
- Disable controls (`KOALA_NO_SESSION`, single-file open, AI/git modes) go through the adapter (`persistence.stop()` for lazyvim).

### D4. Picker routing
`LazyVim.pick` registers a single picker (snacks, from the default `editor.snacks_picker` extra). After it registers, KoalaVim wraps `LazyVim.pick.picker.open(command, opts)`:
- `files`: fff `find_files` (`find_files_in_dir` when `opts.cwd` is set)
- `live_grep` / `grep`: fff `live_grep({ cwd })`
- anything else (`oldfiles`, `git_files`, `grep_word`, …): the snacks picker

`opts.root == false` / `cwd` are honored. KoalaVim's snacks picker layout overrides stay in KoalaVim's snacks spec.

### D5. Trouble v3 port
Swap to `folke/trouble.nvim` (LazyVim's spec). Port `hydras/helpers/trouble.lua` to the v3 API (`require('trouble').open({ mode = … })`, `next/prev({ jump = true })`). KoalaVim's `<leader>t` toggle becomes `Trouble diagnostics toggle filter.buf=0` (KoalaVim's "document" semantics). The `TroubleCursorLine` highlight moves to ofirkai.

### D6. noice + fidget
KoalaVim's noice spec becomes an `opts` function that merges KoalaVim's `routes` from `misc/noice_routes.lua` into LazyVim's opts, keeps `KOALA_NO_NOICE` handling, keeps KoalaVim's hover/signature borders and scroll keys, and sets `lsp.progress.enabled = false`. fidget is unchanged.

### D7. mini.ai, gitsigns, todo-comments
- mini.ai: remove KoalaVim's spec, so LazyVim's `nvim-mini/mini.ai` applies. Check for overlaps between mini.ai objects (`o f c t d e g u U`) and various-textobjs keys (`is as i| a|` + subword/indent/url) and resolve them in KoalaVim's various-textobjs opts.
- gitsigns: KoalaVim's opts function starts from LazyVim's (signs, signs_staged) and adds KoalaVim's settings. Both `on_attach` keymap sets are composed by `flavor-keymaps`; until then KoalaVim's `on_attach` wins.
- todo-comments: same plugin on both sides, so the opts merge. KoalaVim's `]t`/`[t` match LazyVim's.

## Implementation notes (as built)

- **D1, disables:** `plugins/lazyvim.lua` holds `enabled = false` specs for flash, mini.pairs, ts-comments and grug-far. The default `editor.snacks_explorer` extra can't be disabled by import (`vim.g.lazyvim_explorer` only accepts snacks or neo-tree), so KoalaVim sets snacks `explorer.enabled = false` and drops the extra's `<leader>fe/fE/e/E` keys with `{ lhs, false }` fragments. lazy.nvim keeps lockfile entries for disabled plugins.
- **D2, flavor gating:**
  - lualine and bufferline use `config = flavor.is('koala') and fn or nil`, so LazyVim's config runs in the lazyvim flavor. `setup_lualine` (half_screen) has a flavor guard.
  - `vim.g.trouble_lualine = false` applies only in the koala flavor; trouble v3's statusline works in the lazyvim flavor.
  - The snacks dashboard has its `init` in `ui.lua`. lazy.nvim doesn't merge `init`, so anyone adding a snacks `init` must call this one.
  - The dashboard is skipped under `KOALA_RESTART` and `KOALA_MODE`, as alpha is.
  - Extra dashboard buttons use single letters: `a` (AI), `d` (git diff), `u` (update), `C` (changelog).
- **D3, events and adapter:**
  - `User KoalaDashboardClosed` is fired from alpha's `AlphaClosed` and from snacks' `SnacksDashboardClosed`.
  - The session adapter is `utils/session.lua`, with backends in `utils/session_backend/{possession,persistence}.lua`.
  - The persistence backend:
    - must be `lazy = false` (its stock `BufReadPre` trigger would skip the startup disable controls and restart auto-load);
    - is per git branch, falling back to the no-branch file;
    - stores component state in a `<session>.vim.json` sidecar, written on `PersistenceSavePost` and found through `v:this_session`;
    - has no equivalent of possession's `delete_hidden_buffers`.
  - The `Koala*` session globals stay as thin wrappers.
- **D4, picker routing:** done in `utils/pick.lua`, which wraps `LazyVim.pick.picker.open`. Pickers are verified to open fff for `files` and `live_grep` (with the project root as `cwd`) and snacks for everything else.
- **D5, trouble v3:**
  - The old fork's lazy.nvim directory was replaced by a fresh `folke/trouble.nvim` checkout. The fork's locked commit doesn't exist upstream.
  - v3 has no `toggle_mode` or `open_code_href`, so the hydra's `m` head is dropped and `h` opens help.
  - KoalaVim's `<leader>xx/xX/xl/xq` keys are replaced by LazyVim's, until `flavor-keymaps` reconciles them.
- **D6, noice:** KoalaVim's routes are placed *before* LazyVim's, because noice stops at the first match. LazyVim's noice presets (`command_palette`, `bottom_search`, `long_message_to_split`) now also apply in the koala flavor.
- **D7, textobjects:** the real collisions were with treesitter-textobjects (`af`, `ac`, `ie`, `ai`) and with nvim-various-textobjs' new defaults. Its API had changed (renamed opts, `shellPipe` deprecated).
  - mini.ai now owns `af/if`, `ac/ic`, `ae/ie`, `ao/io`, `ad/id`, `at/it`, `ag/ig` and `au/iu`.
  - Call moves to `ak/ik`.
  - Binary expression moves to `ix`.
  - Shell pipe `i|/a|` now uses a bash treesitter query (`queries/bash/textobjects.scm`).
  - Several various-textobjs defaults are disabled; see that file.
- **Pinned snacks.nvim was too old for the pinned LazyVim.** LazyVim's `<c-/>` and `<leader>bi` call `Snacks.terminal.focus` and `Snacks.bufdelete.invisible`, which the pinned snacks lacked. snacks is bumped to upstream `main` (`882c996`), 19 commits of fixes plus those two features. A static check of every `Snacks.*` call in LazyVim found no other gaps.
- **Lockfile generator:** sets `vim.g.koala_all_flavors`, which makes `flavor.is()` true for both flavors during generation. The lockfile therefore covers both flavors' plugins (possession and persistence, alpha, toggleterm).
- **cmp-fuzzy-dictionary:** its `reload` is defined in `after/plugin`, which lazy.nvim doesn't source when the plugin loads during startup. The config now sources `after/plugin` first when needed. This is a pre-existing startup error.

## Risks / Trade-offs

- [Switching flavor hides sessions saved under the other backend] → Documented. `:checkhealth KoalaVim` reports the active flavor and session backend. No automatic migration.
- [persistence lacks named sessions] → Named sessions are koala-flavor only (spec states it).
- [LazyVim internals assume a disabled plugin, e.g. snacks_picker's flash integration or lualine sections referencing noice/dap] → Each is guarded by `LazyVim.has`. Verify that both flavors start without errors.
- [fff wrapping breaks if LazyVim changes the `LazyVim.pick` internals] → The lockfile pins LazyVim; a test opens `LazyVim.pick('files')` and `LazyVim.pick('live_grep')` headless.
- [statuscol.nvim vs LazyVim's statuscolumn option set in `options.lua`] → statuscol sets it later (plugin config), so it wins. Verify that the folds column still renders.

## Open Questions

- Should the snacks dashboard in the lazyvim flavor show KoalaVim's extra buttons (AI, git diff, update, changelog)? Proposed: yes, append them to LazyVim's `dashboard.preset.keys`.
