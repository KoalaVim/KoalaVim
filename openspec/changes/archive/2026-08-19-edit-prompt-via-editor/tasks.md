## 1. EDITOR proxy script

- [x] 1.1 Add `bin/sidekick-editor-proxy` (bash, `set -euo pipefail`) that takes the file path as `$1`, creates a unique FIFO under `${TMPDIR:-/tmp}`, and `trap 'rm -f "$PIPE"' EXIT`
- [x] 1.2 Fail fast with a message on stderr if `$NVIM` is empty or `$1` is missing, **before** blocking on the FIFO
- [x] 1.3 Quote `$1` and the FIFO path as Vim single-quoted strings (`'` doubled to `''`) and invoke `nvim --server "$NVIM" --remote-expr` with `v:lua.require('KoalaVim.utils.ai.general').open_editor_file(<file>, <pipe>)` — this is a one-shot RPC client, not a new Neovim
- [x] 1.4 If `--remote-expr` fails, exit non-zero without `read`ing the FIFO; on success, `read < "$PIPE"` then exit 0
- [x] 1.5 Mark the script executable (`chmod +x`) and keep it in git as `100755`

## 2. Lua handler

- [x] 2.1 Add `M.open_editor_file(file, pipe)` to `lua/KoalaVim/utils/ai/general.lua`, callable via `v:lua` (string args). Return quickly so the proxy can reach `read` before any FIFO write
- [x] 2.2 Open the **real** file path (the CLI temp file) in a below-split of ~30% height, matching `open_prompt_buffer`; set `filetype` to `sidekick_koala_prompt`. Do **not** create a scratch buffer and do **not** call `send_to_sidekick`
- [x] 2.3 On `BufWinLeave` (once): `:update` if the buffer is modified, then unblock the proxy, then refocus the sidekick terminal window if it is still valid (prefer a `sidekick_terminal` window, else the window that was current when the RPC arrived; guard both with `nvim_win_is_valid`)
- [x] 2.4 Write the FIFO byte **asynchronously** (`vim.system` with no `:wait()`), since opening a FIFO for write blocks until the proxy's `read` attaches — doing it on the main loop can freeze the UI
- [x] 2.5 If the `:update` fails, notify at `WARN` and signal the FIFO anyway: a stale prompt is recoverable, a hung CLI is not
- [x] 2.6 Key handler state by FIFO path so two concurrent edit requests stay independent, and tolerate a FIFO that has already vanished (proxy killed) without raising
- [x] 2.7 Attach the same prompt-buffer convenience maps (`<C-f>` files, `<C-b>` buffers) to this buffer so composing still has file/buffer pickers; do not attach history-picker submit behaviour that would inject via `CLEAR_KEYS`
- [x] 2.8 Leave `edit_prompt()`, `open_prompt_with()`, `GET_PROMPT`, `CLEAR_KEYS`, and the `<C-e>` keymap in `lua/KoalaVim/plugins/ai.lua` untouched

## 3. Inject EDITOR at CLI spawn (sidekick fork)

- [x] 3.1 In the sidekick fork (`lua/sidekick/cli/terminal.lua`), next to `NVIM = vim.v.servername`, resolve the proxy with `vim.api.nvim_get_runtime_file('bin/sidekick-editor-proxy', false)[1]`
- [x] 3.2 When the path is found, set both `EDITOR` and `VISUAL` to that absolute path; when it is missing, do not set either (CLI still starts, inherited env unchanged). `VISUAL` matters because it conventionally wins over `EDITOR`, so an inherited `VISUAL=nvim` would otherwise shadow the proxy
- [x] 3.3 Merge them as defaults — *before* the `tool.config.env` / `tool.env` layers — so a tool that configures its own editor still wins; leave `NVIM` in the final layer where it is today
- [ ] 3.4 Point KoalaVim's sidekick.nvim pin at the fork commit that includes the env injection (lazy-lock / plugin spec as this repo already tracks the fork)

## 4. Documentation

- [x] 4.1 In `docs/plugins/ai.md`, note that sidecar-spawned CLIs get `EDITOR`/`VISUAL` pointed at the KoalaVim proxy, so the CLI's native edit-in-editor keybind (Ctrl+X / Ctrl+X Ctrl+E) opens the prompt in the running Neovim
- [x] 4.2 State that `<C-e>` is still the parse-and-inject overlay and is unchanged by this work

## 5. Verification

- [x] 5.1 Run `stylua --check` (or `make` if it wraps formatting) over the modified Lua files
- [x] 5.2 Load check: `nvim_get_runtime_file('bin/sidekick-editor-proxy', false)[1]` resolves, the file is executable, and `require('KoalaVim.utils.ai.general').open_editor_file` exists
- [x] 5.3 Headless smoke test: start `nvim --headless --listen <tmp-socket>`, run the proxy against a temp file, and assert the proxy blocks, the file opens, and closing the buffer releases the proxy with the edited bytes on disk — covers the mechanism without a real CLI
- [ ] 5.4 Manual: in a live cursor or claude sidecar, press the CLI's edit-in-editor keybind — the temp file opens in a Neovim split (no nested nvim), editing + closing the split returns to the TUI with the new prompt
- [ ] 5.5 Manual: edit the buffer and close the split *without* an explicit `:w` — the CLI still receives the edited text
- [ ] 5.6 Manual: close the split without changing the buffer — the CLI keeps the original prompt text and does not hang
- [ ] 5.7 Manual: while the split is open and the CLI is blocked, confirm Neovim stays responsive in other windows
- [ ] 5.8 Manual: a path containing a space and a single quote round-trips correctly
- [ ] 5.9 Manual: `<C-e>` still opens the existing parse-and-inject prompt buffer and still sends via `CLEAR_KEYS` on close
- [x] 5.10 Failure: with `NVIM` unset, running the proxy against a dummy file exits non-zero and does not hang; with the proxy hidden from rtp, a CLI still starts; confirm no FIFO or temp dir is left behind in either case
