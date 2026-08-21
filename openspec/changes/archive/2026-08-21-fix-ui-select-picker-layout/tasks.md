## 1. Restore preset resolution

- [x] 1.1 In `lua/KoalaVim/plugins/editor.lua`, add `layouts = { default = { layout = { ... } } }` to the `snacks.nvim` `picker` opts, moving the existing `box = 'horizontal'` structure (width/height 0.9, vertical list+input box, preview at width 0.5) into it verbatim
- [x] 1.2 Reduce the global `picker.layout` to `{ preset = 'default' }` so it carries no `layout.layout` key, and put `reverse = true` in `layouts.default` with the box it applies to
- [x] 1.3 Confirm `sources.select = { layout = { preset = 'select' } }` is still present and unchanged (an interim `reverse = false` here was removed once D4 scoped `reverse` correctly)

## 2. Per-keymap layouts (dropped)

Removed from scope during implementation. The `gs` and `ss` inline layout tables are not
workarounds for the preset guard — no built-in preset anchors a picker at the cursor, and
`lsp_symbols` has no layout preset to inherit. See design D3.

## 3. Verify

Resolved with snacks' own resolver in a headless Neovim, comparing before/after configs
per source (`Snacks.picker.config.layout`), rather than by eye:

- [x] 3.1 `select` source resolves to a 0.5x0.4 vertical box with `hidden = { 'preview' }` — was 0.9x0.9 horizontal with a visible preview pane. This is the sidekick picker and every other `vim.ui.select` prompt, including the markdown todo-state one
- [x] 3.2 `files`, `lsp_definitions`, `diagnostics` resolve byte-identically before and after: horizontal, 0.9x0.9, `reverse = true`, `list | input | preview:0.5`, nothing hidden
- [x] 3.3 `command_history` (`:CmdHistory`) now resolves its `vscode` preset (0.4x0.4 vertical, no preview) instead of the large box
- [x] 3.4 `stylua --check lua/KoalaVim/plugins/editor.lua` passes
- [x] 3.5 Live check of the sidekick tool picker: geometry and highlights correct, but the dimmed backdrop was gone
- [x] 3.6 Restore the backdrop with `layout.layout = { backdrop = 60 }` on the global config, and confirm `select` / `files` / `command_history` all resolve `backdrop = 60`, matching the pre-fix config
- [x] 3.7 Live check of `:CmdHistory` found results stranded at the bottom of the list. Fixed per D4 by moving `reverse` into `layouts.default`; confirmed `reverse` now tracks box order across `files`, `diagnostics`, `select`, `command_history`, `spelling`, `search_history`, `icons`
