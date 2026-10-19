## Context

`KoalaVim.utils.ai.general.send_context(kind)` is the single entry point for the send-context keys (`<M-a>` = "this", `<M-A>` / `<leader>af` = "file", visual `<M-a>`). It already has one plugin-specific provider: `utils/plugins/codediff.lua`'s `context_text(kind)`, which returns `(text, handled)`. `send_context` then routes the text:

- prompt editor open (`find_prompt_win()`) → `insert_text_in_prompt(text)` (focuses the prompt and `nvim_put`s the lines)
- otherwise → `with_default_tool(sidekick.cli.send, { text = text })`

Inside nvim-tree, `vim.api.nvim_buf_get_name(0)` is the tree buffer, so today the keys send a useless `@NvimTree_1` reference. nvim-tree is lazy-loaded (`cmd = 'NvimTreeOpen'` / keys), so the provider must only touch `nvim-tree.api` when the current buffer is an NvimTree buffer.

## Goals / Non-Goals

**Goals:**
- Reuse the existing keys and routing; the tree becomes just another context provider.
- Support the node under cursor, visual selection of nodes, and nvim-tree marks.
- Files and directories.

**Non-Goals:**
- No new keymaps in the tree and no sidekick.nvim changes.
- Not sending file *contents* — explorer context is references only (sidekick reads the files itself).
- Other file explorers (neo-tree, oil, …).

## Decisions

### Provider module mirroring codediff
Add `lua/KoalaVim/utils/plugins/nvim_tree.lua` exposing `context_text(kind) -> (text|nil, handled)`. It returns `nil, false` unless `vim.bo.filetype == 'NvimTree'`, so it costs nothing elsewhere and never loads nvim-tree on its own.

`general.lua` gets a small provider list (`codediff`, `nvim_tree`) used by both `render_context` (prompt editor path) and `send_codediff_context` (renamed to a generic provider-send helper). *Alternative:* a separate tree-only keymap/function — rejected, it duplicates routing and diverges from `<M-a>` muscle memory.

### Node selection order: visual range → marks → cursor
- Visual mode: map rows `line('v')..line('.')` to nodes. nvim-tree has no public row→node API, so move the cursor across the range and call `api.tree.get_node_under_cursor()` per row, then restore the cursor and exit visual mode.
- Normal mode with marks: `api.marks.list()`, ordered by tree order where possible (fallback: path sort), then `api.marks.clear()` after the text is produced.
- Otherwise: `api.tree.get_node_under_cursor()`.
Nodes without `absolute_path` (root header) are dropped; an empty result notifies and returns `nil, true` (handled, nothing sent).

*Alternative:* marks take priority over visual selection — rejected; an explicit visual selection is the more recent intent.

### Reference formatting via sidekick's Loc
Build each reference with `require('sidekick.cli.context.location').get({ name = abs_path }, { kind = 'file' })` so it matches sidekick's `@path` rendering (cwd-relative, same highlight groups) and the prompt-editor `<C-f>` insertion. Directories get a trailing `/` so the AI can tell them apart. References are joined on one line with spaces (same shape as `_send_cb` in sidekick's picker), returned as `sidekick.Text[]`.

`"this"` and `"file"` behave the same in the tree (there is no cursor position inside a file); `"selection"` is the visual-mode path.

### Visual `<M-a>` in the tree
`<M-a>` in `x` mode is a global lazy key, so it already fires in the tree buffer. Its kind is `'this'`; the provider detects visual mode itself (`vim.fn.mode()` is `v`/`V` when the mapping runs) rather than relying on the kind.

## Risks / Trade-offs

- [Walking the cursor for visual ranges triggers CursorMoved autocmds in the tree] → restore the original cursor afterwards; ranges are small, cost is negligible.
- [`api.marks.list()` order is not tree order] → sort by tree order when the explorer exposes it, otherwise by path; order is cosmetic for the AI.
- [Clearing marks surprises users who use marks for bulk fs ops] → only cleared after a successful send from the tree; documented in the spec.
- [Paths outside cwd] → `Loc.get` falls back to the absolute path, which is still a valid reference.
