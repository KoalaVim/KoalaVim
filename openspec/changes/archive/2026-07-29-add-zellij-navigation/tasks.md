## 1. Zellij mux backend

- [x] 1.1 Create `lua/KoalaVim/utils/plugins/navigator_zellij.lua` as a class extending `require('Navigator.mux.vi')`, following the shape of upstream `Navigator.mux.wezterm`; use tab indentation and single quotes per `stylua.toml`
- [x] 1.2 Add the direction → CLI argument table: `move-focus` for all of `h`/`j`/`k`/`l` (pane-scoped, never crossing tabs, matching the tmux and wezterm backends) plus `p` = `{ 'focus-previous-pane' }` (argument lists, not fixed pairs — `p` takes no direction)
- [x] 1.3 Implement `Zellij:new()` with `assert(vim.env.ZELLIJ ~= nil, ...)` so a direct call fails honestly, returning a `setmetatable` instance like the wezterm backend
- [x] 1.4 Implement `Zellij:navigate(direction)`: look up the argument list, spawn `{ 'zellij', 'action', unpack(args) }` via `vim.system` with `{ text = true }`, and `return self`; make an unknown direction a no-op rather than a `nil` index
- [x] 1.5 In the `vim.system` callback, on non-zero exit `vim.schedule` a `vim.notify` at `vim.log.levels.WARN` with the collapsed stderr (`vim.trim(stderr:gsub('%s+', ' '))`)
- [x] 1.6 Add a comment explaining that `zoomed()` is inherited from `vi` and returns `false` on purpose — Navigator only calls it when `disable_on_zoom` is true, and querying Zellij fullscreen would need a blocking `list-panes` on every keypress
- [x] 1.7 Add a header comment covering the two-sided contract: Zellij must be in locked mode (e.g. via `zellij-autolock`) for `<C-hjkl>` to reach Neovim, and this module handles the other direction — handing focus off once Neovim is already at its own edge

## 2. Wire the backend into Navigator

- [x] 2.1 In `lua/KoalaVim/plugins/editor.lua`, in the `numToStr/Navigator.nvim` spec's `config` function, resolve the mux before `setup`: when `vim.env.ZELLIJ` is set, `pcall` the Zellij backend's `new()` and use the instance; otherwise leave `mux = 'auto'`
- [x] 2.2 Make a failed `pcall` fall back to `'auto'` rather than erroring, so a Navigator internals change degrades to today's behaviour
- [x] 2.3 Add a comment stating why `$ZELLIJ` is checked instead of extending Navigator's `load_mux()`: Zellij nested inside WezTerm sets both `$ZELLIJ` and `TERM_PROGRAM=WezTerm`, and the innermost multiplexer must win
- [x] 2.4 Update the plugin's leading comment from "tmux/wezterm panes" to include zellij; leave `disable_on_zoom = false` and all `<C-h/j/k/l>` keymaps untouched

## 3. Documentation

- [x] 3.1 Update the Navigator.nvim row in `docs/plugins/editor.md` to name zellij alongside tmux/wezterm
- [x] 3.2 Note the Zellij-side prerequisite (locked mode via `zellij-autolock`, `zellij` on `PATH`) so a non-working setup is diagnosable

## 4. Verification

- [x] 4.1 Run `stylua --check` (or `make` if it wraps formatting) over the new and modified files
- [x] 4.2 Load check outside Zellij: start Neovim, confirm `:lua print(require('Navigator.navigate').config.mux)` is not the Zellij backend and that `<C-h/j/k/l>` still move between splits with no errors
- [x] 4.3 Manual check inside a Zellij session with a pane to the left of Neovim: from the leftmost split, `<C-h>` moves focus to that Zellij pane; with a split to the left, `<C-h>` moves within Neovim and issues no `zellij` command
- [x] 4.4 Manual check that no direction crosses a Zellij tab at the session edge
- [ ] 4.5 Manual check in terminal mode and in the sidekick.nvim CLI split that the same keys hand off correctly
- [x] 4.6 Force a failure (e.g. temporarily point the command at a bogus zellij action) and confirm a WARN notification appears and Neovim stays usable
- [ ] 4.7 If a nested setup is available, confirm Zellij-inside-WezTerm drives Zellij and not WezTerm

## Verification notes

Verified from inside a live Zellij session (`$ZELLIJ=0`) running the real
KoalaVim config headless via `kv --headless`. Focus-move commands were asserted
by intercepting `vim.system` and checking the exact argv, so the live session was
never disturbed.

- 4.1 — `stylua --check` clean on both changed Lua files.
- 4.2 — With `ZELLIJ` unset, the resolved mux is *not* the Zellij backend,
  `disable_on_zoom` stays `false`, `auto_save` stays `nil`, and all four
  `<C-hjkl>` keymaps still resolve to `<Cmd>Navigator*<CR>`. With `$ZELLIJ` set,
  the resolved mux *is* the Zellij backend.
- 4.3 / 4.4 — Asserted at the argv level: a split in the direction moves within
  Neovim and issues no `zellij` command; at the edge the window is unchanged and
  exactly `move-focus <left|right|up|down>` is issued, never
  `move-focus-or-tab`. Observing focus actually land in the neighbouring Zellij
  pane is really a check of Zellij itself and was not driven.
- 4.5 — Partial. All four `<C-hjkl>` are confirmed mapped in terminal mode. The
  sidekick.nvim CLI split was not exercised (needs a live AI CLI session); it
  reuses the same `Navigator*` commands, so no separate code path is involved.
- 4.6 — Real `vim.system` spawn with a bogus action produced a
  `vim.log.levels.WARN` notification prefixed `zellij action failed: ` carrying
  the collapsed stderr; Neovim stayed usable.
- 4.7 — Not verifiable here: the host terminal is ghostty, so no WezTerm layer
  exists to nest under. The `$ZELLIJ` check makes the outcome deterministic by
  construction, but it is unexercised.

Also confirmed directly: `new()` asserts when `$ZELLIJ` is absent, `zoomed()`
inherits `false` from `Navigator.mux.vi`, an unknown direction is a no-op
returning `self` rather than a `nil` index, and `p` maps to
`focus-previous-pane` with no direction argument.

Scratch harnesses used (not added to the repo — there is no Lua test harness to
slot them into): `test_zellij.lua` (backend unit checks), `check_wiring.lua`
(mux resolution + keymaps), `check_handoff.lua` (edge detection + argv).
