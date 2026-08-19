## Why

Editing an AI CLI prompt today means scraping the terminal buffer's rendered text (box characters, prompt markers, per-agent parsers) and then blasting key sequences to clear the TUI and inject the rewrite. That round-trip is fragile — a CLI UI tweak breaks parsing — and lossy. The CLIs already have a native "edit in `$EDITOR`" path; we should use it so Neovim is the editor of record instead of a screen scraper.

## What Changes

- Add a KoalaVim `$EDITOR` proxy (`bin/sidekick-editor-proxy`) that the CLI invokes as a normal editor. The proxy talks to the already-running Neovim over RPC (`nvim --server "$NVIM" --remote-expr`) and blocks until the user closes the file.
- Add a Lua handler that opens the CLI's temp file in a split, and on `BufWinLeave` signals the proxy (via FIFO) so the CLI can read the edited file back as the new prompt.
- Inject `EDITOR` when sidekick spawns CLI tools, pointing at the proxy (auto-discovered on the runtime path). Sidekick already sets `NVIM = vim.v.servername`; the proxy uses that socket.
- Users trigger this via each CLI's native "edit in editor" keybind (Ctrl+X for cursor/codex, Ctrl+X Ctrl+E for claude), not via KoalaVim's `<C-e>`.
- The existing `<C-e>` / buffer-parse / `CLEAR_KEYS` flow is **unchanged** in this change. History picker (`open_prompt_with`) and cursor Question TUI handling are out of scope.

## Capabilities

### New Capabilities

None. This extends the existing AI integration rather than introducing a new capability.

### Modified Capabilities

- `ai-integration`: the **Prompt editing in editor buffer** area gains a native `$EDITOR` round-trip. When a sidekick-spawned CLI invokes `$EDITOR` on a temp file, that file SHALL open in the running Neovim, and closing the buffer SHALL unblock the CLI so it can adopt the edited content. The existing KoalaVim `<C-e>` parse-and-inject path is not replaced here.

## Impact

- **New file**: `bin/sidekick-editor-proxy` — shell proxy that creates a FIFO, RPC-opens the file in Neovim, and blocks until the Lua handler writes the FIFO.
- **Modified**: `lua/KoalaVim/utils/ai/general.lua` — add `open_editor_file(file, pipe)` for the RPC handler (split + `BufWinLeave` → FIFO). The existing `edit_prompt()`, `get_prompt()` parsers, and `CLEAR_KEYS` stay.
- **Modified (sidekick.nvim fork)**: `lua/sidekick/cli/terminal.lua` — set `EDITOR` alongside the existing `NVIM = vim.v.servername` env, resolving the proxy via `nvim_get_runtime_file('bin/sidekick-editor-proxy')`.
- **Unchanged**: `lua/KoalaVim/plugins/ai.lua` `<C-e>` keymap, per-agent `get_prompt()` modules, question TUI, history picker.
- **Dependencies**: the `ofirgall/sidekick.nvim` fork (env injection lives there). The proxy requires `NVIM` to be the running instance's server socket, which sidekick already provides.
- **Out of scope**: rewriting `<C-e>` to drive this path; cursor Question TUI; history picker (`open_prompt_with`); VISUAL vs EDITOR distinction beyond setting `EDITOR`.
