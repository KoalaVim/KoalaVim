# Editor

General editor enhancements and QoL utilities.

| Plugin | Description |
| --- | --- |
| [AutoSave.nvim](https://github.com/ofirgall/AutoSave.nvim) | Auto-save files on changes. |
| [guess-indent.nvim](https://github.com/KoalaVim/guess-indent.nvim) | Auto-detect indentation style (tabs vs spaces, width) per file. |
| [NeoZoom.lua](https://github.com/ofirgall/NeoZoom.lua) | Zoom the current split into a full-screen floating window. |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlight and navigate TODO/FIXME/HACK/NOTE comments. |
| [nvim-colorizer.lua](https://github.com/KoalaVim/nvim-colorizer.lua) | Highlight color codes (#RRGGBB, rgb(), named colors) inline. |
| [scope.nvim](https://github.com/tiagovla/scope.nvim) | Scope buffers to their tab (tab-local buffer lists). |
| [nvim-FeMaco.lua](https://github.com/gen4438/nvim-FeMaco.lua) | Edit markdown code fences in a floating window with proper LSP/formatting. |
| [open.nvim](https://github.com/ofirgall/open.nvim) | Open URL/file/issue-ref under the cursor in the right external app. |
| [open-jira.nvim](https://github.com/ofirgall/open-jira.nvim) | open.nvim handler for Jira ticket references. |
| [nvim-retrail](https://github.com/zakharykaplan/nvim-retrail) | Highlight and trim trailing whitespace/blank lines at EOF. |
| [Navigator.nvim](https://github.com/numToStr/Navigator.nvim) | Unified window navigation between Neovim splits and tmux/wezterm/zellij panes. |
| [hex.nvim](https://github.com/RaafatTurki/hex.nvim) | Toggle current buffer between text and hexdump view. |
| [suda.vim](https://github.com/lambdalisue/suda.vim) | Read/write files requiring sudo from inside Neovim. |
| [vim-buffest](https://github.com/rbong/vim-buffest) | Edit quickfix, location list and registers as regular buffers. |
| [vim-log-highlighting](https://github.com/ofirgall/vim-log-highlighting) | Syntax highlighting for generic log files. |
| [nvim-genghis](https://github.com/ofirgall/nvim-genghis) | File operations inside Neovim (rename, trash, move, duplicate, chmod). |
| [highlight-undo.nvim](https://github.com/tzachar/highlight-undo.nvim) | Flash-highlight regions affected by undo/redo. |
| [muren.nvim](https://github.com/AckslD/muren.nvim) | Multiple-replace UI with live preview. |
| [undotree](https://github.com/mbbill/undotree) | Visual tree browser of the full undo history. |
| [interestingwords.nvim](https://github.com/ofirgall/interestingwords.nvim) | Persistently highlight arbitrary words in multiple colors. |
| [trouble.nvim](https://github.com/ofirgall/trouble.nvim) | Pretty panel for diagnostics, quickfix, loclist, references. |
| [gitlinker.nvim](https://github.com/linrongbin16/gitlinker.nvim) | Generate permalinks to the current line on the git host. |
| [nvim-spectre](https://github.com/nvim-pack/nvim-spectre) | Project-wide find and replace with live preview. |
| [scrollofffraction.nvim](https://github.com/nkakouros-original/scrollofffraction.nvim) | Dynamic scrolloff based on a fraction of the window height. |
| [command-and-cursor.nvim](https://github.com/moyiz/command-and-cursor.nvim) | Keep visual selection highlighted while in command-line mode. |
| [bracket-repeat.nvim](https://github.com/ofirgall/bracket-repeat.nvim) | Repeat the last `]x`/`[x` bracket motion. |
| [marks.nvim](https://github.com/ofirgall/marks.nvim) | Visual sign column for Vim marks plus enhanced mark bindings. |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | folke QoL grab-bag: notifier, dim, scroll, input, picker, dashboard, etc. |
| [nerdy.nvim](https://github.com/2kabhishek/nerdy.nvim) | Browse and insert Nerd Font icons from a picker. |

## Zellij navigation

Navigator.nvim has no zellij backend upstream, so KoalaVim supplies one
(`KoalaVim.utils.plugins.navigator_zellij`). It is selected when `$ZELLIJ` is
set, which also means it wins over wezterm when zellij is nested inside it — the
innermost multiplexer owns the pane Neovim lives in.

Two things are needed on the zellij side, neither of which KoalaVim can do for
you:

- **Zellij must be in locked mode while nvim is focused**, otherwise zellij
  keeps `<C-hjkl>` for itself and Neovim never sees the keys. The
  [zellij-autolock](https://github.com/fresh2dev/zellij-autolock) plugin does
  this automatically; it matches on the pane's running command, so a wrapper
  script around nvim needs to be added to its trigger list. `zellij action
  list-clients` shows the command it matches against.
- **`zellij` must be on `PATH`.** Handoff shells out to `zellij action`; a
  failure surfaces as a warning notification rather than failing silently.

Navigation is pane-scoped in every direction and never crosses zellij tabs,
matching the tmux and wezterm backends. At the edge of the tab, focus stays put.
