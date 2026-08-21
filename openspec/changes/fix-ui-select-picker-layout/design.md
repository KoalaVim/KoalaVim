## Context

`snacks.picker` resolves a picker's layout by merging four sources in order: built-in defaults, the user's global `picker` config, the source-specific config (`picker.sources.<name>`), and the per-call opts. Layout *presets* (`default`, `select`, `ivy`, `telescope`, ...) are resolved afterwards, but only under a guard:

```lua
-- snacks/picker/config/init.lua:224
-- only resolve presets when the layout has no layout
if not (layout.layout and layout.layout[1]) then
  ... walk and merge the preset chain ...
end
```

KoalaVim's global config (`lua/KoalaVim/plugins/editor.lua:681`) supplies an explicit box list in `picker.layout.layout`. That satisfies `layout.layout[1]`, so preset resolution is skipped for *every* picker. Consequences:

```
config merge (defaults -> user -> source -> opts)
  user  : layout = { preset='default', reverse=true, layout={ box='horizontal', [1]=..., [2]=preview } }
  source: layout = { preset='select' }                    <- 'select' wins the preset key
  ------------------------------------------------------
  merged: preset='select'  AND  layout.layout=[user box]
                                        |
                                        v
                          preset chain never walked
                          -> select preset's hidden={'preview'} lost
                          -> select preset's compact box lost
```

The select source's items carry no `file` or `buf`. The default previewer therefore errors, and `snacks/picker/core/preview.lua:417` renders `vim.inspect(self.item)` into the preview buffer as the error detail. For sidekick that item wraps a `sidekick.cli.State` (tool, session, backend, pids, cwd), which is the table dump the user sees.

Two prior commits are part of this story. `234ab48` set only `width`/`height` under `layout.layout` — no `[1]` key, so presets still resolved and the bug did not exist. `f1cfa7f` added `box = 'horizontal'` plus child window entries, which tripped the guard. `7950eae` then patched two symptoms by inlining full layout tables at the `gs` and `ss` keymaps instead of fixing the guard condition.

## Goals / Non-Goals

**Goals:**
- Restore preset resolution so per-source layout presets take effect.
- `vim.ui.select` prompts render as a compact, preview-less popup.
- Preserve the current appearance of file, grep, LSP, and diagnostic pickers exactly.
- Remove the need for per-keymap inline layout workarounds.

**Non-Goals:**
- Changing which picker backend handles files or grep (`fff.nvim` stays).
- Changing `sidekick.nvim`. Its tool selector always calls `vim.ui.select` (`lua/sidekick/cli/ui/select.lua:57`); `Config.cli.picker` only governs file/context pickers, so it is not a lever here.
- Restyling the main picker layout, borders, or dimensions.
- Filling the preview pane with useful content for select items.

## Decisions

### D1: Redefine `layouts.default` instead of adding a new named preset

Move the custom box list into `picker.layouts.default` and reduce the global `picker.layout` to `{ preset = 'default', reverse = true }`.

The custom layout is the built-in `default` preset with three deltas: 0.9 instead of 0.8, no `min_width`, and input below list instead of above. It is not a new layout, it is a redefinition of the default one. Overriding `layouts.default` says exactly that, and every source that already asks for `default` inherits it with no further wiring.

Mechanically this works because `snacks/picker/config/init.lua:227` reads `opts.layouts` from the merged config, so a user `layouts.default` deep-merges over the built-in. A box list carrying `[1]` is not dict-like, so `Snacks.config.merge` (`snacks/init.lua:72`) replaces it wholesale rather than merging index-by-index — the custom box fully supplants the built-in one.

Alternatives considered:
- A new preset name such as `layouts.koala`. Rejected: the preset slot describes a layout's *shape and role*, not its owner, and it adds a name that every call site must then reference.
- `layout = { preset = 'telescope', layout = { width = 0.9, height = 0.9 } }`. The built-in `telescope` preset (`snacks/picker/config/layouts.lua:44`) is already `reverse = true`, horizontal, list above input, preview right — nearly the hand-built layout. Rejected for now because it differs cosmetically: preview 0.45 vs 0.5, and per-window borders with centered titles instead of one bordered vertical box. Adopting it would change the look of every main picker, which is outside this change's scope. Worth a follow-up if the smaller config is preferred over pixel-identical output.
- `sources.select = { layout = { hidden = { 'preview' } } }` on top of the current global. Rejected: hides the dump but leaves a 0.9x0.9 window for a three-item list, and does nothing for the `gs`/`ss` class of workaround.

### D2: Keep `sources.select = { layout = { preset = 'select' } }`

The entry already exists and is currently dead. After D1 it becomes effective, delivering the built-in `select` preset: vertical box, 0.5 width capped at 80-100 columns, `hidden = { 'preview' }`, and list height fitted to the item count. No new config needed for the sidekick picker specifically.

### D3: Leave the `gs` and `ss` inline layouts alone

Revised during implementation. An earlier draft of this design called the inline layout tables from `7950eae` redundant once presets resolve again, and scheduled them for conversion to `preset = 'select'` plus overrides. Checking the source defaults showed that premise was wrong:

| Source | Built-in layout | What the keymap wants |
| --- | --- | --- |
| `spelling` (`ss`) | `preset = 'vscode'` — top-anchored, full width | 40x10 popup at the cursor |
| `lsp_symbols` (`gs`) | none at all | 100x15 popup at the cursor |

Both keymaps compute `row`/`col` from `vim.fn.screenpos` at call time. No built-in preset anchors a picker at the cursor, and `lsp_symbols` carries no layout preset to inherit. So these tables encode a requirement the preset system does not cover; they are not workarounds for the guard described in D1. They also already set `reverse = false`, which is still needed to stop the global `reverse = true` from leaking in.

Converting them anyway would mean reproducing the cursor anchoring on top of a preset that pins `min_width = 80` (against `ss`'s desired 40), for no reduction in hardcoded dimensions and with a visual regression risk that cannot be verified without a live UI. Out of scope.

## Risks / Trade-offs

- [D1 changes `default` for sources that explicitly request `preset = 'default'` rather than inheriting it] → That is the intent; the previous global config already forced the same box on them. No behavior change expected.
- [`reverse = true` now merges onto resolved presets rather than being part of a fixed box] → Resolved: `reverse` only controls list item ordering (`snacks/picker/core/list.lua:191`), not box order, so the `select` preset keeps its input on top while results would render bottom-up, putting the first match furthest from the input. `sources.select` therefore sets `reverse = false`, matching the `gs` and `ss` popups which already pair input-on-top with `reverse = false`.
- [Presets resolving again will change the appearance of other pickers that previously fell through to the global box] → This is a real, intended widening. Sources in `snacks/picker/config/sources.lua` carrying their own `layout` key are `explorer` (disabled here), `command_history`, `icons`, `lines`, `search_history`, `select`, `spelling`, and `gh_reactions` / `gh_labels` / `gh_actions`. The `max_width = 50` cap belongs to the three `gh_*` sources, not to `spelling`. The one reachable here without an explicit per-call override is `command_history` (`:CmdHistory`), which now resolves its `vscode` preset — top-anchored, no preview — instead of the large box. `spelling` and `lsp_symbols` are unaffected because their keymaps pass a full per-call layout (see D3).

## Migration Plan

Config-only change, no state or data. Rollback is reverting the commit.

Verification does not need a live UI for the parts that matter. Loading `snacks.nvim` in a headless Neovim and calling `Snacks.picker.config.layout(Snacks.picker.config.get({ source = ... }))` under the old and new picker opts resolves each source's final layout, which is exactly what the guard in D1 affects. Compare per source and assert:

1. `select` changes from horizontal 0.9x0.9 with a visible preview to vertical 0.5x0.4 with `hidden = { 'preview' }`.
2. `files`, `lsp_definitions`, `diagnostics` are identical before and after.
3. `command_history` changes from the large box to its own `vscode` preset.

Only the subjective read of the new sidekick picker needs a live session.

## Open Questions

- Should the follow-up to `preset = 'telescope'` (D1 alternative 2) be filed as its own change, or dropped? It trades a pixel-identical layout for roughly 12 fewer lines of config.
