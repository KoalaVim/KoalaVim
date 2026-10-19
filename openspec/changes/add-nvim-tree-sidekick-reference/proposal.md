## Why

When browsing the project in nvim-tree, there is no way to hand a file (or directory) to the AI sidekick: the existing send-context keys (`<M-a>`, `<M-A>`, `<leader>af`) act on the current buffer, which inside nvim-tree is the tree itself. Users have to leave the tree, open the file or use a picker just to reference a path they are already looking at.

## What Changes

- Make the existing send-context keys tree-aware: when invoked from an nvim-tree buffer, they reference the node(s) from the tree instead of the tree buffer.
- Reference targets, in priority order: visually selected nodes (visual-mode `<M-a>`), nvim-tree marked nodes (bookmarks), otherwise the node under the cursor.
- Files and directories are both supported; references use the same `@path` format sidekick uses for file context (cwd-relative).
- Respect the existing routing: if the Koala prompt editor is open, the references are inserted into it; otherwise they are sent to the sidekick CLI (via the default tool).
- Clear nvim-tree marks after they were sent, so the next send doesn't resend them.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `ai-integration`: the "Context sending" requirement gains file-explorer context — sending from nvim-tree references the tree's node(s) and is routed to the prompt editor or sidekick like other context.

## Impact

- `lua/KoalaVim/utils/ai/general.lua`: `send_context` / `render_context` gain an nvim-tree context provider, alongside the existing codediff provider.
- New `lua/KoalaVim/utils/plugins/nvim_tree.lua` (mirrors `utils/plugins/codediff.lua`): builds sidekick text from tree nodes.
- `lua/KoalaVim/plugins/ai.lua`: `<M-a>` in visual mode must also work in the NvimTree buffer (no new keys expected).
- Depends on nvim-tree's public API (`nvim-tree.api`: `tree.get_node_under_cursor`, `marks.list`, `marks.clear`); no sidekick.nvim changes required.
