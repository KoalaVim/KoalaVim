## Why

`<C-h/j/k/l>` currently hands focus off to a neighbouring terminal-multiplexer pane only under tmux or WezTerm, because those are the only backends Navigator.nvim ships. Inside a Zellij session the keys stop dead at the edge of Neovim's window layout, so navigation silently breaks for Zellij users. A working port already exists outside this repo (`configs/nvim-atom/lua/atom/zellij.lua`) and should become a first-class KoalaVim backend.

## What Changes

- Add a Zellij multiplexer backend for Navigator.nvim, living in KoalaVim and implementing Navigator's `Vi` mux interface (`new`, `navigate`, `zoomed`).
- Select that backend explicitly when `$ZELLIJ` is set, so Zellij wins over WezTerm when Neovim runs in a Zellij pane inside WezTerm (Zellij is the innermost multiplexer and owns the pane layout Neovim sits in).
- Fall back to Navigator's existing `mux = 'auto'` detection (tmux → WezTerm → no-op) when `$ZELLIJ` is absent, leaving current behaviour byte-identical for non-Zellij users.
- All four directions use `zellij action move-focus`, keeping navigation pane-scoped and never crossing Zellij tabs, matching the tmux (`select-pane -LRUD`) and wezterm (`activate-pane-direction`) backends.
- Run the `zellij` CLI asynchronously via `vim.system` and surface a warning notification when the action exits non-zero, so a failed handoff is visible instead of silent.
- Document the backend and its Zellij-side prerequisite (Zellij must be in locked mode — e.g. via `zellij-autolock` — for `<C-hjkl>` to reach Neovim at all).
- No keymap changes: `<C-h/j/k/l>` in normal and terminal mode, plus the sidekick.nvim CLI window nav keys, keep calling `Navigator*` commands.

## Capabilities

### New Capabilities

None. This extends an existing capability rather than introducing a new one.

### Modified Capabilities

- `editor-enhancements`: the **Cross-pane navigation** requirement currently names tmux and WezTerm as the supported multiplexers. It gains Zellij, the innermost-multiplexer selection rule, and the requirement that a failed multiplexer handoff is reported rather than swallowed.

## Impact

- **New file**: `lua/KoalaVim/utils/plugins/navigator_zellij.lua` — the mux backend.
- **Modified**: `lua/KoalaVim/plugins/editor.lua` — the `numToStr/Navigator.nvim` spec passes the resolved `mux` in `config`.
- **Modified**: `docs/plugins/editor.md` — the Navigator.nvim row mentions Zellij.
- **Dependencies**: no new plugins. Depends on Navigator.nvim's internal `Navigator.mux.vi` base class, which is documented as the extension point for custom multiplexers, and on the `zellij` binary being on `PATH` inside a Zellij session.
- **Out of scope**: the Zellij side of the contract (`config.kdl` keybindings, the `zellij-autolock` plugin) lives in the user's dotfiles, not in KoalaVim. It is documented as a prerequisite only.
- **Unaffected**: `<C-hjkl>` keymaps, tmux/WezTerm users, `disable_on_zoom = false`, and the sidekick.nvim nav keys.
