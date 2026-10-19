## 1. nvim-tree context provider

- [x] 1.1 Create `lua/KoalaVim/utils/plugins/nvim_tree.lua` with `context_text(kind)` returning `nil, false` unless the current buffer's filetype is `NvimTree`
- [x] 1.2 Collect nodes: visual range (walk rows with `api.tree.get_node_under_cursor()`, restore cursor, exit visual mode) → `api.marks.list()` → node under cursor
- [x] 1.3 Drop nodes without `absolute_path`; on an empty result notify "No nvim-tree node to reference" and return `nil, true`
- [x] 1.4 Format each node with `sidekick.cli.context.location`.get(`{ name = abs_path }`, `{ kind = 'file' }`), append `/` for directories, join on one line with spaces as `sidekick.Text[]`
- [x] 1.5 Clear marks with `api.marks.clear()` after marks were used to produce the text

## 2. Route through send_context

- [x] 2.1 In `lua/KoalaVim/utils/ai/general.lua`, introduce a provider list (`codediff`, `nvim_tree`) and use it in `render_context` (prompt-editor path)
- [x] 2.2 Generalize `send_codediff_context` into a provider-send helper used by `send_context` (sidekick path), keeping codediff behavior unchanged
- [x] 2.3 Verify the visual `<M-a>` keymap in `plugins/ai.lua` reaches the provider in the NvimTree buffer while still in visual mode (adjust the mapping if it exits visual first)

## 3. Verify

- [x] 3.1 Manual: in nvim-tree, `<M-a>` on a file and on a directory sends `@path` / `@dir/` to sidekick
- [x] 3.2 Manual: visual-select several tree lines + `<M-a>` sends all of them in order
- [x] 3.3 Manual: mark nodes (`m`), `<M-a>` sends the marked nodes and marks are cleared
- [x] 3.4 Manual: with the Koala prompt editor open, `<M-a>` in the tree inserts the references into the prompt editor and focuses it
- [ ] 3.5 Manual: `<M-a>` on the root header line notifies and sends nothing; `<M-a>` in a normal buffer and in codediff behaves as before
- [x] 3.6 Run `openspec validate add-nvim-tree-sidekick-reference`
