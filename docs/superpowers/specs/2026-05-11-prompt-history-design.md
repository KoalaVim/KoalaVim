# Prompt History — Design

Save every prompt sent via `edit_prompt` so the user can later fuzzy-find past prompts, scoped by workspace and branch.

## Goals

- Persist the prompt content + small metadata each time `edit_prompt` sends to the sidekick CLI.
- Provide three pickers: current workspace+branch, current workspace (all branches), and everything.
- Selecting a past prompt either loads it into a new `edit_prompt` buffer (editable) or sends it directly.
- No new plugin dependencies. Use only what KoalaVim already pulls in (snacks.nvim, neovim built-ins).

## Non-goals

- Retention/rotation policy. JSONL grows unbounded; pruning can be added later.
- Sharing history across machines.
- Indexing or full-text engines — flat-file scan + snacks fuzzy is enough.

## Storage

### Layout

```
<vim.fn.stdpath('state')>/koala/prompts/<workspace>/<branch>/prompts.jsonl
```

- `<workspace>` — basename of `cwd`: `vim.fn.fnamemodify(cwd, ':t')` (e.g. `KoalaVim`).
- `<branch>` — current git branch with `/` replaced by `__` (e.g. `feat/foo` → `feat__foo`).
  - Non-git directory → `no-branch`.
  - Detached HEAD → `detached-<sha7>`.
- Directories created lazily with `vim.fn.mkdir(dir, 'p')` on first write.

### Record format

One JSON object per line, encoded with `vim.json.encode`:

```json
{"ts": 1731350000, "cwd": "/home/ofirg/.local/share/kvim-envs/main/lazy/KoalaVim", "agent": "claude", "branch": "master", "prompt": "...multi-line content with \\n preserved..."}
```

Fields:

- `ts` — `os.time()` at append.
- `cwd` — `vim.fn.getcwd()` at send time (full path; on-disk path uses basename, so `cwd` disambiguates collisions if the user inspects records).
- `agent` — `claude` | `codex` | `cursor` (from `state.tool.name`).
- `branch` — resolved branch string (same value used in the on-disk path).
- `prompt` — full prompt text. `vim.json.encode` handles newlines.

Records are written redundantly with their path on purpose: a record read in isolation (e.g., user `cat`s a file) is still self-describing.

### Branch detection (no shell-out)

Read `<cwd>/.git/HEAD`:

- File contains `ref: refs/heads/<name>\n` → branch is `<name>`.
- File contains a 40-char sha → `detached-<sha[:7]>`.
- File missing or unreadable → `no-branch`.

If `<cwd>/.git` is a file (worktree/submodule), follow the `gitdir:` pointer to find the actual `HEAD`. If anything fails, fall back to `no-branch`. Resolution happens on every append; a `pcall` wraps the whole thing so write path errors never block sending.

## Module

New file: `lua/KoalaVim/utils/ai/history.lua`.

Public API:

- `append(prompt: string, agent: string)` — resolve workspace+branch, ensure dir exists, append one JSONL record. All failure paths use `pcall`; never throws.
- `pick_local()` — open snacks picker over the current `prompts.jsonl`.
- `pick_workspace()` — open snacks picker over all branches of the current workspace.
- `pick_global()` — open snacks picker over the entire `prompts/**/prompts.jsonl` tree.

Internal helpers:

- `resolve_path(cwd)` → `{ dir, file, workspace, branch }`
- `resolve_branch(cwd)` → branch string
- `read_file(path)` → list of decoded records
- `list_files(scope)` → list of jsonl paths
- `load(scope)` → list of records (each augmented with the source file path)

## Write path integration

In `lua/KoalaVim/utils/ai/general.lua`, inside the `BufWinLeave` handler set up by `edit_prompt`, just before `state.session:send(content)`:

```lua
pcall(function()
  require('KoalaVim.utils.ai.history').append(content, state.tool.name)
end)
```

The existing `content ~= ''` guard is reused — empty content is not appended.

## Pickers

Built on `Snacks.picker` (already a dep). One implementation, scope passed in.

### Implementation: pure Lua, async streaming

Justification: at expected scale (hundreds–low thousands of records), `vim.json.decode` on the full set runs in well under 100ms and the append path is microseconds. Shelling out to `jq`/`rg`/`fd` adds dependencies and fork overhead without meaningful speedup. Responsiveness comes from running the work off the UI thread, not from changing language.

Mechanism:

- File discovery uses `vim.fs.find` (built-in, no dep). For `local` scope this is a single path check; for `workspace` and `global` it walks one or two directory levels.
- The snacks picker source is an async finder: it `yield`s items as records are decoded, so the picker window opens immediately and rows stream in. Decoding work is chunked (e.g., yield after every N records) to keep the event loop responsive.
- Reading uses `vim.uv.fs_open` / `fs_read` with a single read per file (files are small, line-oriented). Lines are split on `\n` and decoded one by one; bad lines are skipped silently.

### Item display

Each picker item shows one row:

```
HH:MM  YYYY-MM-DD  ·  <agent>  ·  <workspace>/<branch>  ·  <first non-empty line of prompt>
```

Fuzzy search matches against the whole row, so the user can type the agent name, branch, or text from the prompt body and it just works.

### Preview pane

Full prompt body, multi-line. No syntax highlighting (treat as plain text).

### Keymaps inside the picker

- `<CR>` — load the prompt into a new `edit_prompt` buffer prefilled with the historical content. User can edit and close-to-send (existing flow). Requires picker to know the currently attached agent — fall back to `get_attached_agent()`; if none attached, surface a notify and bail.
- `<C-s>` — send directly. Wraps the existing `sidekick.cli.state.with(...)` pattern with `state.session:send(record.prompt)` and reuses the clear-key sequence from `CLEAR_KEYS`.

### Sort order

Newest first. Records are appended chronologically, so reverse the loaded list before feeding it to the picker.

## Refactor of `edit_prompt`

Currently `edit_prompt` derives initial buffer lines from `GET_PROMPT[agent]()`. Extract the buffer-opening logic into a local helper:

```lua
local function open_prompt_buffer(initial_lines, term_win) ... end
```

`edit_prompt` calls it with `get_prompt()` output. The history "load" action calls it with the historical prompt's lines (split on `\n`). All other behavior — autocmds, keymaps, send-on-close — is shared.

## Public surface in `general.lua`

Add thin wrappers so external keymap files can bind without requiring the history module directly:

- `M.pick_prompt_history_local()`
- `M.pick_prompt_history_workspace()`
- `M.pick_prompt_history_global()`

No keymaps added by this change. Bindings are the user's call.

## Error handling

- All disk I/O wrapped in `pcall`. Append failures `vim.notify` at `WARN` once and continue.
- JSON decode errors during read skip the offending line and continue.
- Picker on empty scope shows an info notify ("no prompt history yet") and returns.

## Testing approach

Manual smoke test in a live Neovim session:

1. Send a prompt via `edit_prompt`. Verify the JSONL file appears at the expected path with one record.
2. Switch branches; send another prompt. Verify a new directory for the new branch is created.
3. `cd` to a non-git directory; send a prompt. Verify it lands under `no-branch`.
4. Open each picker; verify scope filtering, item rows, preview, `<CR>` (loads into edit buffer), `<C-s>` (sends directly).
5. Corrupt one line of a jsonl file; verify the picker still loads the rest.

No automated tests — KoalaVim has no test infrastructure to plug into.
