## Why

Every `vim.ui.select()` call opens a full-size 0.9x0.9 picker with a preview pane containing a `vim.inspect()` dump of the selected item. The sidekick agent picker is the visible symptom: choosing an AI CLI tool shows a large window with a Lua table dump of `sidekick.cli.State` where a preview would go.

The cause is config shape, not the picker choice. `snacks.picker.layout` in `lua/KoalaVim/plugins/editor.lua` sets an explicit `layout.layout` box list. Snacks skips preset resolution entirely when that key holds a list (`snacks/picker/config/init.lua:224`), so the `select` source's `preset = 'select'` (which carries `hidden = { 'preview' }`) never applies. Regression introduced in `f1cfa7f`; the same defect was already worked around by hand for two other pickers in `7950eae`.

## What Changes

- Move the custom 0.9x0.9 horizontal picker layout from the global `picker.layout` into `picker.layouts.default`, redefining the built-in `default` preset rather than inlining a box list globally.
- Reduce the global `picker.layout` to `{ preset = 'default' }` so it carries no `layout.layout` key and preset resolution runs again. `reverse = true` moves into `layouts.default` with the box it belongs to, rather than staying at config level where it would override every preset.
- `sources.select = { layout = { preset = 'select' } }` (already present but dead) becomes effective: `vim.ui.select` pickers get the compact, preview-less select layout.

No visual change to file, grep, LSP, or diagnostic pickers.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `fuzzy-finder`: the "UI-select routing" and "Picker layout and interaction" requirements gain scenarios specifying that selection prompts use a compact preview-less layout, and that per-source layout overrides take effect.

## Impact

- `lua/KoalaVim/plugins/editor.lua` — `snacks.nvim` opts, `picker.layout` / `picker.layouts` / `picker.sources.select`. Single file changed.
- `:CmdHistory` now resolves the `vscode` preset instead of the large box. The `gs` and `ss` keymaps in `lua/KoalaVim/plugins/pickers.lua` are unaffected — they pass a full per-call layout (see design D3).
- Affects every `vim.ui.select()` consumer, including `sidekick.nvim` tool selection (`lua/sidekick/cli/ui/select.lua:57`) and the markdown todo-state prompt (`lua/KoalaVim/plugins/lsp/servers/markdown.lua:183`).
- No plugin additions or removals. No `lazy-lock.json` change.
