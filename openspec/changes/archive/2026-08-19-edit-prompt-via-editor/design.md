## Context

`M.edit_prompt()` in `lua/KoalaVim/utils/ai/general.lua` composes prompts by screen-scraping. Each agent ships a `get_prompt()` (`cursor.lua`, `claude.lua`, `codex.lua`) that reads the rendered terminal buffer and strips box-drawing characters and prompt markers (`❯`, `^›`, ` ┌─`). The text is dropped into a scratch split; on `BufWinLeave`, `send_to_sidekick()` clears the live TUI with `CLEAR_KEYS` (Ctrl+C for claude/cursor, per-line Ctrl+U preceded by a computed cursor walk for codex) and re-sends the whole prompt through `state.session:send()`. Every step is a guess about how the CLI draws and how it responds to control characters, and every CLI release can invalidate those guesses.

All three CLIs already expose a native "edit in `$EDITOR`" binding — Ctrl+X for cursor and codex, Ctrl+X Ctrl+E for claude. The CLI writes the current prompt to a temp file, runs `$EDITOR <file>`, waits for the process to exit, reads the file back, and replaces its prompt with the contents. That contract gives us exact text in and exact text out with no parsing and no key injection. The missing piece is an `$EDITOR` that renders in the Neovim instance the CLI is embedded in rather than spawning a nested one.

Sidekick already supplies the hook: `lua/sidekick/cli/terminal.lua` (~line 282) builds the child environment and sets `NVIM = vim.v.servername`, so every CLI it spawns knows the socket of its host Neovim. KoalaVim runs a fork (`ofirgall/sidekick.nvim`), so that file is ours to edit.

Constraints:

- The CLI blocks on the editor process. Whatever we set as `$EDITOR` must be a real process that stays alive for the duration of the edit and exits exactly once, or the CLI hangs or reads a half-written file.
- `--remote-expr` runs on Neovim's main loop. The handler must return promptly; it cannot be the thing that waits for the user.
- KoalaVim is a shared distribution. The change must degrade to something usable when the socket, the proxy, or the RPC is unavailable.

## Goals / Non-Goals

**Goals:**

- A sidekick-spawned CLI invoking `$EDITOR <file>` opens that file in the already-running Neovim, and the CLI resumes with the edited contents once the user closes the buffer.
- No terminal-buffer parsing and no control-character injection anywhere on this path.
- Agent-agnostic: one proxy and one handler serve cursor, claude, and codex, because the `$EDITOR` contract is the same for all three.
- Graceful degradation when the RPC or the proxy is unavailable — the CLI keeps running and never hangs.
- The existing `<C-e>` path keeps working untouched, so the two can be compared side by side before either is retired.

**Non-Goals:**

- Rewriting `<C-e>` to drive this path, or removing `get_prompt()` / `CLEAR_KEYS`. Follow-up once this has been used in anger.
- Cursor's Question TUI, which is a different widget with a different clear key and no `$EDITOR` affordance.
- The history picker (`open_prompt_with`) — it has no CLI-side file to round-trip through.
- Full feature parity with the `<C-e>` buffer — history recall and submit-on-close semantics stay out. See Decision 8.
- `GIT_EDITOR` or any environment variable beyond `EDITOR` and `VISUAL`.
- Upstreaming the sidekick change; the fork carries it for now.

## Decisions

### 1. A shell script on the runtime path, not an inline `$EDITOR` command

`$EDITOR` is set to the absolute path of `bin/sidekick-editor-proxy`, shipped in this repo and located at spawn time with `vim.api.nvim_get_runtime_file('bin/sidekick-editor-proxy', false)[1]`.

A script is required, not merely convenient. The CLI appends the filename and expects the resulting process to block; an inline `nvim --server … --remote-expr …` string would return the instant the expression was evaluated, and the CLI would read the file back before the user had typed anything. The script is what owns the waiting.

Runtime-path discovery rather than a hardcoded path keeps the proxy working across the several checkouts this config lives in and requires no user configuration. If the lookup returns nothing, `EDITOR` is simply not set and the CLI falls back to whatever the user's environment already had — a missing feature, not a broken terminal.

*Alternative considered:* generate the script into `stdpath('cache')` at startup. Rejected — a tracked, reviewable file beats a generated one, and there is nothing dynamic to template into it.

### 2. `--remote-expr` plus a FIFO, not `--remote-wait`

Neovim's `nvim --server X --remote-wait <file>` already blocks until the buffer is deleted, which looks like an exact fit. We do not use it, for two reasons. It gives no control over *how* the file is opened — it lands in the server's current window, which at that moment is the sidekick terminal itself, replacing the CLI's own view. And it offers no hook to run KoalaVim-side setup (split geometry, buffer-local keymaps, refocusing the terminal on exit).

So the proxy splits the two halves of the job:

1. Create a FIFO in a private temp directory.
2. `nvim --server "$NVIM" --remote-expr "…open_editor_file(<file>, <fifo>)"` — returns as soon as the split is open.
3. `read < "$fifo"` — blocks the proxy, and therefore the CLI, until Neovim writes a byte.

The handler stays off the critical path and the waiting happens in a process that is allowed to wait.

*Alternative considered:* poll for a sentinel file in a `while sleep 0.1` loop. Rejected — a FIFO is the primitive for exactly this and adds neither latency nor a busy loop.

### 3. Neovim signals the FIFO asynchronously

Opening a FIFO for writing blocks until a reader attaches. Doing that on Neovim's main loop would freeze the editor whenever the proxy is not yet reading — including the small window between the `--remote-expr` returning and the shell reaching its `read`. The handler therefore signals through a detached `vim.system({ 'sh', '-c', … })` with no `:wait()`, so the block (if any) lands in a throwaway process.

This also makes a dead proxy harmless: if the user quit the CLI mid-edit, the writer simply never completes and is reaped with Neovim, instead of wedging the UI.

### 4. Write the buffer before signalling

The CLI reads the temp file the moment the proxy exits, so the signal must come strictly after the bytes are on disk. On `BufWinLeave` the handler writes the buffer if it is modified, and only signals once the write succeeded. If the write fails, the handler still signals — a stale prompt is recoverable, a hung CLI is not — but notifies at warning level so the loss is visible rather than silent.

`BufWinLeave` (rather than `BufDelete` or `WinClosed`) matches what the existing `<C-e>` buffer uses, so "close the split to submit" is the same gesture on both paths.

### 5. Fail fast rather than falling back to a nested editor

If `$NVIM` is unset or the `--remote-expr` call fails, the proxy prints a diagnostic and exits non-zero without ever reaching the `read`. It does not fall back to `vi` or a nested `nvim`.

The instinct is to fall back so the user still gets *an* editor, but the fallback is close to dead code: `EDITOR` is only injected by sidekick, and sidekick always sets `NVIM` in the same table. The realistic failure is a host Neovim that has died — and the CLI is a child of that Neovim's terminal, so it dies with it. What a fallback would actually buy is a surprise nested `vi` rendering inside the CLI's own TUI. Exiting non-zero leaves the CLI's prompt exactly as it was, which is the recoverable outcome.

`--remote-expr` writes its errors to stderr, which is the CLI's TUI. The proxy captures that output and folds it into its own diagnostic rather than letting it corrupt the rendered prompt.

### 6. Escape paths for Vimscript, not just for the shell

The paths are interpolated into a Vimscript expression string, so shell quoting alone is insufficient — a filename containing a quote would break the expression or, worse, evaluate as code. The proxy embeds each path as a single-quoted Vimscript literal, where the only escape needed is doubling `'`. Backslashes are literal inside single-quoted Vimscript strings, so Windows-style paths and escaped characters pass through untouched.

### 7. Set both `EDITOR` and `VISUAL`, as defaults; `NVIM` stays authoritative

Both variables are set to the proxy. This is not belt-and-braces: the convention is that `VISUAL` wins over `EDITOR` for full-screen editors, so a user whose shell exports `VISUAL=nvim` would have our `EDITOR` silently ignored and get a nested Neovim inside the CLI's terminal — the exact failure this change exists to remove. Setting both closes that hole. Anything more nuanced about the two (respecting a deliberate `VISUAL`, `GIT_EDITOR`, and so on) is out of scope.

In `terminal.lua` the environment is layered `os_environ` → `tool.config.env` → `tool.env` → `{ NVIM = …, TERM = …, … }`, last writer winning. Both variables go in *before* the per-tool layers, so a tool config that deliberately sets its own editor still wins. `NVIM` stays in the final layer where it is today: the proxy's correctness depends on it pointing at this instance, and a per-tool override would be a bug, not a preference.

### 8. Reuse the `sidekick_koala_prompt` filetype and split geometry

The editor buffer opens as a below-split at the same ~30% height as the existing prompt buffer, carries the same buffer-local picker keymaps (`<C-f>` files, `<C-b>` buffers), and is given the `sidekick_koala_prompt` filetype.

The filetype is doing real work in this config, not just labelling. `find_prompt_win()` keys off it, so `send_context()` inserts `{this}` / `{file}` / `{selection}` into this buffer instead of blasting them at the terminal; a `FileType` autocmd in `config_lazy/autocmds/misc.lua` turns on spell-check for it; and `utils/ui.lua` already excludes it from window decoration. Reusing it means the new buffer behaves like the prompt buffer users already know, with no new wiring.

The cost is the CLI's own file type — claude's `.md` temp file loses markdown highlighting. That is worth trading for the integration, and it is reversible later by switching `find_prompt_win()` to a buffer variable if syntax turns out to matter.

Everything beyond this is deferred: no history recall, no submit-on-close semantics. The buffer's only obligation is to persist and signal.

### 9. Refocus the sidekick terminal on close

Like the existing flow, the handler restores focus to the terminal window when the split closes, so the user lands back where they pressed the key. It resolves the target by preferring a window whose buffer filetype is `sidekick_terminal` and falling back to whichever window was current when the RPC arrived, guarding both against having been closed meanwhile.

### 10. Verification is manual, with a headless smoke test

The repo has no test harness and the behaviour is interactive. Verification is a manual matrix across the three CLIs plus a headless script that starts `nvim --listen` on a temp socket, runs the proxy against a temp file, and asserts that the proxy blocks, that the file opens, and that closing the buffer releases it with the edited contents on disk. That covers the mechanism without needing a real CLI in the loop.

## Risks / Trade-offs

- **The proxy exits without the file having been edited** (Neovim killed, buffer force-closed) → the CLI reads the file unchanged and the prompt is untouched. A no-op is the correct failure mode here; nothing is lost.
- **User opens the same temp file twice**, or a second CLI invokes the editor while one edit is in flight → each invocation has its own FIFO and its own handler state keyed by that FIFO, so the two are independent. The buffer is keyed by file path, so a genuine double-open of the same path reuses the window and the last close wins.
- **The `read` never returns** because Neovim died after the split opened but before signalling → the proxy blocks forever. In practice the CLI is a child of that Neovim's terminal and dies with it, so the orphan is short-lived. A timeout on the `read` was considered and rejected: it is far more likely to truncate a long edit than to rescue a dead instance.
- **FIFO and temp directory leak** if the proxy is killed uncatchably → `trap EXIT` covers ordinary termination including Ctrl+C; a `SIGKILL` leaves a directory under the system temp path, which is the OS's problem to reap.
- **The change lives in a fork of sidekick.nvim** → `terminal.lua` will conflict on upstream merges. The edit is two lines in one already-forked table, and the env block is stable upstream.
- **Native keybinds are the only trigger**, so discoverability depends on the user knowing the CLI's own shortcut, which differs per agent (Ctrl+X vs Ctrl+X Ctrl+E). Accepted for now; folding this into `<C-e>` is the follow-up that removes the inconsistency.
- **Two prompt-editing paths coexist** during the transition, with different behaviour and different keys. Deliberate — it makes the new path comparable against the old one before the parsers are deleted.

## Migration Plan

Purely additive. The proxy is a new file, `open_editor_file()` is a new function, and the sidekick edit only adds an environment variable. Nothing on the `<C-e>` path is touched, so there is no state to migrate and no user-visible behaviour that changes without the user pressing a new key.

Rollback is dropping the `EDITOR`/`VISUAL` line in `terminal.lua`; the CLIs revert to their inherited editor and the proxy plus handler become dead code.

## Open Questions

- Should `<C-e>` be re-pointed at this path once it has proven itself, and if so, does it drive the CLI's native binding by sending its key sequence, or keep the two triggers distinct?
- Cursor's Question TUI has no `$EDITOR` affordance. Does it stay on the parse-and-inject path indefinitely, which would mean `get_prompt()` and `CLEAR_KEYS` survive even after the main flow migrates?
- Setting `EDITOR` process-wide means tools the agent shells out to (`git commit`, for instance) also route into Neovim. That is probably a feature, but it has not been tried and could surprise.
