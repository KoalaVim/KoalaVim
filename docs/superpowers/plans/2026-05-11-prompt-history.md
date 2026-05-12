# Prompt History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist every prompt sent via `edit_prompt` to a per-workspace/per-branch JSONL file, with three snacks pickers (local / workspace / global) for fuzzy-finding history.

**Architecture:** New module `lua/KoalaVim/utils/ai/history.lua` owns storage and picker logic. `lua/KoalaVim/utils/ai/general.lua` is refactored to extract its buffer-opening logic so both `edit_prompt` and the picker "load" action can prefill content, and a one-line hook in the existing `BufWinLeave` callback writes records on send.

**Tech Stack:** Lua, Neovim built-ins (`vim.json`, `vim.fs`, `vim.uv`, `vim.fn.stdpath`), Snacks.nvim picker. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-05-11-prompt-history-design.md`

**Testing note:** KoalaVim has no automated test infrastructure. Verification is done via manual smoke tests inside a live Neovim session at task boundaries. Each task ends with explicit `:lua` commands or user-driven flows to confirm behavior before committing.

---

## File Structure

- **Create:** `lua/KoalaVim/utils/ai/history.lua` — storage + picker module
- **Modify:** `lua/KoalaVim/utils/ai/general.lua` — refactor `edit_prompt`, add write hook, add picker wrappers

---

### Task 1: Create history module skeleton with path resolution

**Files:**
- Create: `lua/KoalaVim/utils/ai/history.lua`

- [ ] **Step 1: Create the module file**

Create `lua/KoalaVim/utils/ai/history.lua` with branch detection and path resolution:

```lua
local M = {}

local function read_file_contents(path)
	local fd = vim.uv.fs_open(path, 'r', 438)
	if not fd then
		return nil
	end
	local stat = vim.uv.fs_fstat(fd)
	if not stat then
		vim.uv.fs_close(fd)
		return nil
	end
	local data = vim.uv.fs_read(fd, stat.size, 0)
	vim.uv.fs_close(fd)
	return data
end

local function sanitize_branch(name)
	return (name:gsub('/', '__'))
end

local function resolve_branch(cwd)
	local git_path = cwd .. '/.git'
	local stat = vim.uv.fs_stat(git_path)
	if not stat then
		return 'no-branch'
	end

	local head_path
	if stat.type == 'directory' then
		head_path = git_path .. '/HEAD'
	else
		-- .git is a file pointing at gitdir (worktree/submodule)
		local contents = read_file_contents(git_path)
		if not contents then
			return 'no-branch'
		end
		local gitdir = contents:match('^gitdir:%s*(.-)%s*$')
		if not gitdir then
			return 'no-branch'
		end
		if gitdir:sub(1, 1) ~= '/' then
			gitdir = cwd .. '/' .. gitdir
		end
		head_path = gitdir .. '/HEAD'
	end

	local head = read_file_contents(head_path)
	if not head then
		return 'no-branch'
	end
	local ref = head:match('^ref:%s*refs/heads/(.-)%s*$')
	if ref then
		return sanitize_branch(ref)
	end
	local sha = head:match('^([0-9a-f]+)%s*$')
	if sha and #sha >= 7 then
		return 'detached-' .. sha:sub(1, 7)
	end
	return 'no-branch'
end

local function root_dir()
	return vim.fn.stdpath('state') .. '/koala/prompts'
end

--- Resolve the on-disk paths for the current cwd.
---@param cwd? string defaults to vim.fn.getcwd()
---@return { dir: string, file: string, workspace: string, branch: string }
function M.resolve_path(cwd)
	cwd = cwd or vim.fn.getcwd()
	local workspace = vim.fn.fnamemodify(cwd, ':t')
	if workspace == '' then
		workspace = 'unknown'
	end
	local branch = resolve_branch(cwd)
	local dir = string.format('%s/%s/%s', root_dir(), workspace, branch)
	return {
		dir = dir,
		file = dir .. '/prompts.jsonl',
		workspace = workspace,
		branch = branch,
	}
end

function M._root_dir()
	return root_dir()
end

return M
```

- [ ] **Step 2: Manually verify path resolution**

Open Neovim in the KoalaVim repo and run:

```vim
:lua vim.print(require('KoalaVim.utils.ai.history').resolve_path())
```

Expected: a table with `workspace = "KoalaVim"`, `branch = "master"` (or current branch), `file` ending in `prompts/KoalaVim/<branch>/prompts.jsonl`.

Also test a branch-with-slash scenario by checking out a branch with `/` in its name (or fake it):

```vim
:lua vim.print(require('KoalaVim.utils.ai.history').resolve_path('/tmp'))
```

Expected: `branch = "no-branch"`, `workspace = "tmp"`.

- [ ] **Step 3: Commit**

```bash
git add lua/KoalaVim/utils/ai/history.lua
git commit -m "feat(ai): add prompt history path resolution"
```

---

### Task 2: Implement append

**Files:**
- Modify: `lua/KoalaVim/utils/ai/history.lua`

- [ ] **Step 1: Add the `append` function**

Append to `lua/KoalaVim/utils/ai/history.lua` (before `return M`):

```lua
--- Append a prompt record to the per-workspace/per-branch JSONL file.
--- Never throws; on failure, emits a single WARN notify.
---@param prompt string
---@param agent string
function M.append(prompt, agent)
	local ok, err = pcall(function()
		local cwd = vim.fn.getcwd()
		local paths = M.resolve_path(cwd)
		vim.fn.mkdir(paths.dir, 'p')
		local record = {
			ts = os.time(),
			cwd = cwd,
			agent = agent,
			branch = paths.branch,
			prompt = prompt,
		}
		local line = vim.json.encode(record) .. '\n'
		local fd = assert(vim.uv.fs_open(paths.file, 'a', 420))
		vim.uv.fs_write(fd, line, -1)
		vim.uv.fs_close(fd)
	end)
	if not ok then
		vim.notify('prompt history: append failed: ' .. tostring(err), vim.log.levels.WARN)
	end
end
```

- [ ] **Step 2: Manually verify append**

In Neovim:

```vim
:lua require('KoalaVim.utils.ai.history').append('hello world', 'claude')
:lua require('KoalaVim.utils.ai.history').append('multi\nline\nprompt', 'claude')
:lua vim.print(require('KoalaVim.utils.ai.history').resolve_path().file)
```

Then in a shell:

```bash
cat "$(nvim --headless -c 'lua io.write(require("KoalaVim.utils.ai.history").resolve_path().file)' -c 'qa' 2>&1)"
```

Or simpler, from inside Neovim:

```vim
:edit `=require('KoalaVim.utils.ai.history').resolve_path().file`
```

Expected: two lines of valid JSON, each with `ts`, `cwd`, `agent="claude"`, `branch`, `prompt` fields. The multi-line prompt should appear with `\n` escapes inside the JSON string.

- [ ] **Step 3: Clean up the test data**

```bash
rm "$(realpath ~/.local/state/nvim)/koala/prompts/KoalaVim/$(git rev-parse --abbrev-ref HEAD | tr / __)/prompts.jsonl"
```

Or just delete the file you opened in step 2 from within Neovim.

- [ ] **Step 4: Commit**

```bash
git add lua/KoalaVim/utils/ai/history.lua
git commit -m "feat(ai): append prompt records to JSONL history"
```

---

### Task 3: Wire append into `edit_prompt` send path

**Files:**
- Modify: `lua/KoalaVim/utils/ai/general.lua` (inside the `BufWinLeave` callback, around line 200-215)

- [ ] **Step 1: Add the history.append call**

In `lua/KoalaVim/utils/ai/general.lua`, find the `BufWinLeave` callback inside `M.edit_prompt` (around line 197). Inside the `if content ~= '' then` branch, right before the `require('sidekick.cli.state').with(...)` call, add:

```lua
				if content ~= '' then
					require('KoalaVim.utils.ai.history').append(content, agent)
					-- Using internal sidekick cli to not parse "{}" variables
					require('sidekick.cli.state').with(function(state)
```

The `agent` variable is already in scope (captured from `check_agent()` at the top of `edit_prompt`).

- [ ] **Step 2: Manually verify end-to-end write**

Launch Neovim, open a sidekick CLI (claude/codex/cursor), trigger `edit_prompt`, type a test prompt like `e2e history test`, and close the buffer to send.

Then open the history file:

```vim
:edit `=require('KoalaVim.utils.ai.history').resolve_path().file`
```

Expected: the last line of the file contains `"prompt":"e2e history test"` and `"agent":"<your tool>"`.

- [ ] **Step 3: Verify failure is non-fatal**

Temporarily break the path by stubbing `mkdir` to fail. From Neovim:

```vim
:lua vim.fn.mkdir = function() error('forced failure') end
```

Trigger `edit_prompt`, send a prompt, and confirm:
- The prompt was still sent to the agent.
- A WARN notification appeared mentioning `prompt history: append failed`.

Restart Neovim to restore `vim.fn.mkdir`.

- [ ] **Step 4: Commit**

```bash
git add lua/KoalaVim/utils/ai/general.lua
git commit -m "feat(ai): record prompts to history on send"
```

---

### Task 4: Implement file discovery and record loading

**Files:**
- Modify: `lua/KoalaVim/utils/ai/history.lua`

- [ ] **Step 1: Add discovery helpers**

Append to `lua/KoalaVim/utils/ai/history.lua` (before `return M`):

```lua
--- List jsonl file paths for the given scope.
---@param scope 'local' | 'workspace' | 'global'
---@return string[]
function M.list_files(scope)
	local paths = M.resolve_path()
	if scope == 'local' then
		if vim.uv.fs_stat(paths.file) then
			return { paths.file }
		end
		return {}
	end

	local root
	if scope == 'workspace' then
		root = root_dir() .. '/' .. paths.workspace
	elseif scope == 'global' then
		root = root_dir()
	else
		error('unknown scope: ' .. tostring(scope))
	end

	if not vim.uv.fs_stat(root) then
		return {}
	end

	return vim.fs.find('prompts.jsonl', {
		path = root,
		type = 'file',
		limit = math.huge,
	})
end

--- Read and decode all records from a single jsonl file.
--- Bad lines are skipped silently.
---@param path string
---@return table[]
function M.read_file(path)
	local data = read_file_contents(path)
	if not data then
		return {}
	end
	local records = {}
	for line in data:gmatch('[^\n]+') do
		local ok, decoded = pcall(vim.json.decode, line)
		if ok and type(decoded) == 'table' then
			decoded._file = path
			table.insert(records, decoded)
		end
	end
	return records
end
```

- [ ] **Step 2: Manually verify discovery**

Make sure you have some history records first (use Task 3's send path, or call `append` directly a few times across different scopes — e.g., `cd /tmp` and trigger appends to create a `no-branch` entry).

In Neovim:

```vim
:lua vim.print(require('KoalaVim.utils.ai.history').list_files('local'))
:lua vim.print(require('KoalaVim.utils.ai.history').list_files('workspace'))
:lua vim.print(require('KoalaVim.utils.ai.history').list_files('global'))
:lua vim.print(require('KoalaVim.utils.ai.history').read_file(require('KoalaVim.utils.ai.history').resolve_path().file))
```

Expected:
- `local` returns exactly one path (the current branch's file) or empty list.
- `workspace` returns one path per branch of the current repo.
- `global` returns every jsonl under `prompts/`.
- `read_file` returns a list of tables, each with `ts`, `cwd`, `agent`, `branch`, `prompt`, `_file`.

- [ ] **Step 3: Verify corrupted lines are skipped**

Append a bad line to your local history file:

```bash
echo '{ this is not valid json' >> "$(nvim --headless -c 'lua io.write(require("KoalaVim.utils.ai.history").resolve_path().file)' -c 'qa' 2>&1 | tail -1)"
```

Or from within Neovim:

```vim
:lua local p = require('KoalaVim.utils.ai.history').resolve_path().file; local f = io.open(p, 'a'); f:write('{not json\n'); f:close()
:lua vim.print(#require('KoalaVim.utils.ai.history').read_file(require('KoalaVim.utils.ai.history').resolve_path().file))
```

Expected: count matches the valid records only; no error.

- [ ] **Step 4: Commit**

```bash
git add lua/KoalaVim/utils/ai/history.lua
git commit -m "feat(ai): list and read prompt history files"
```

---

### Task 5: Refactor `edit_prompt` to extract buffer-opening helper

**Files:**
- Modify: `lua/KoalaVim/utils/ai/general.lua` (lines 170-271, the entire `M.edit_prompt` function)

This refactor is a pure rearrangement — no behavior change. The goal is for `M.edit_prompt` to call a local helper `open_prompt_buffer(agent, initial_lines, term_win)` so a future picker action can pass historical content.

- [ ] **Step 1: Add the helper and rewrite `edit_prompt`**

In `lua/KoalaVim/utils/ai/general.lua`, replace the existing `M.edit_prompt` function (currently at lines 170-271) with this pair:

```lua
--- Opens a split with a temporary buffer for editing a prompt and sends it
--- to the sidekick CLI on close. `initial_lines` is the prefilled content.
---@param agent string
---@param initial_lines string[]
---@param term_win integer the window to refocus after closing
local function open_prompt_buffer(agent, initial_lines, term_win)
	local bufid = vim.api.nvim_create_buf(false, true)

	-- Enter insert mode when focusing the buffer
	vim.api.nvim_create_autocmd('BufEnter', {
		buffer = bufid,
		once = true,
		callback = vim.schedule_wrap(function()
			vim.api.nvim_feedkeys('G$a', 'n', false)
		end),
	})

	-- Send content to sidekick CLI when closing the buffer
	vim.api.nvim_create_autocmd('BufWinLeave', {
		buffer = bufid,
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(bufid, 0, -1, false)
			local content = table.concat(lines, '\n')
			if content ~= '' then
				require('KoalaVim.utils.ai.history').append(content, agent)
				-- Using internal sidekick cli to not parse "{}" variables
				require('sidekick.cli.state').with(function(state)
					-- Clear current prompt content
					local termbufid = state.terminal.buf
					local clear_key = CLEAR_KEYS[state.tool.name] or '\x03'
					vim.api.nvim_chan_send(vim.bo[termbufid].channel, clear_key)

					state.session:send(content)
				end, {
					attach = true,
					filter = {},
					focus = true,
					show = true,
				})
			end

			-- Re-focus the terminal window so we stay in the same tabpage
			if vim.api.nvim_win_is_valid(term_win) then
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(term_win) then
						vim.api.nvim_set_current_win(term_win)
					end
				end)
			end
		end,
	})

	local win_id = vim.api.nvim_open_win(bufid, true, {
		split = 'below',
		height = math.ceil(vim.o.lines * 0.3),
	})

	vim.bo[bufid].filetype = 'sidekick_koala_prompt'
	vim.api.nvim_buf_set_lines(bufid, 0, -1, false, initial_lines)

	---@param items sidekick.context.Loc[]
	local paste_to_buffer_cb = function(items)
		local Loc = require('sidekick.cli.context.location')
		local ret = { { ' ' } } ---@type sidekick.Text
		for _, item in ipairs(items) do
			local file = Loc.get(item, { kind = 'file' })[1]
			if file then
				vim.list_extend(ret, file)
				ret[#ret + 1] = { ' ' }
			end
		end
		vim.schedule(function()
			local text = table.concat(
				vim.tbl_map(function(c)
					return c[1]
				end, ret),
				''
			)
			vim.api.nvim_set_current_win(win_id)
			vim.api.nvim_put({ text }, '', true, true)
		end)
	end

	local picker = require('sidekick.cli.picker').get()

	-- FIXME: show hidden files in sidekick as well
	vim.keymap.set({ 'n', 'i' }, '<C-f>', function()
		picker.open('files', paste_to_buffer_cb, { hidden = true })
	end, { buffer = bufid })

	vim.keymap.set({ 'n', 'i' }, '<C-b>', function()
		picker.open('buffers', paste_to_buffer_cb, {})
	end, { buffer = bufid })
end

--- Opens a split with a temporary buffer for editing a prompt.
--- On closing the buffer, sends its content to sidekick CLI.
function M.edit_prompt()
	local agent = check_agent()
	if not agent then
		return
	end

	local get_prompt = GET_PROMPT[agent]()
	local current_prompt_lines = get_prompt()
	local term_win = vim.api.nvim_get_current_win()

	open_prompt_buffer(agent, current_prompt_lines, term_win)
end

--- Open the edit-prompt buffer prefilled with arbitrary content.
--- Used by the history picker to "load" a past prompt.
---@param content string
function M.open_prompt_with(content)
	local agent = check_agent()
	if not agent then
		return
	end
	local term_win = vim.api.nvim_get_current_win()
	local lines = vim.split(content, '\n', { plain = true })
	open_prompt_buffer(agent, lines, term_win)
end
```

Notice the history.append call is preserved from Task 3 inside `open_prompt_buffer` — make sure it's there.

- [ ] **Step 2: Manually verify `edit_prompt` still works**

In Neovim with a sidekick CLI attached, trigger `edit_prompt`, type something, close the buffer. Confirm:
- The prompt is sent to the agent (clear-key fires, content arrives).
- A new line appears in the history JSONL.
- Focus returns to the terminal window.

This is the same behavior as before — the refactor must not change it.

- [ ] **Step 3: Commit**

```bash
git add lua/KoalaVim/utils/ai/general.lua
git commit -m "refactor(ai): extract open_prompt_buffer helper"
```

---

### Task 6: Implement the snacks picker (async streaming)

**Files:**
- Modify: `lua/KoalaVim/utils/ai/history.lua`

- [ ] **Step 1: Add the picker function**

Append to `lua/KoalaVim/utils/ai/history.lua` (before `return M`):

```lua
local function format_row(record)
	local time_str = os.date('%Y-%m-%d %H:%M', record.ts or 0)
	local workspace = vim.fn.fnamemodify(record.cwd or '', ':t')
	local branch = record.branch or 'no-branch'
	local first_line = (record.prompt or ''):match('[^\n]*') or ''
	if #first_line > 120 then
		first_line = first_line:sub(1, 117) .. '...'
	end
	return string.format(
		'%s · %s · %s/%s · %s',
		time_str,
		record.agent or '?',
		workspace,
		branch,
		first_line
	)
end

--- Open a snacks picker over the given scope. Selecting a prompt with <CR>
--- opens an editable buffer; <C-s> sends it directly.
---@param scope 'local' | 'workspace' | 'global'
function M.pick(scope)
	local files = M.list_files(scope)
	if #files == 0 then
		vim.notify('prompt history: nothing recorded yet', vim.log.levels.INFO)
		return
	end

	local Snacks = require('snacks')

	---@type snacks.picker.finder
	local finder = function(_, ctx)
		local out = {}
		for _, path in ipairs(files) do
			local records = M.read_file(path)
			-- Reverse: newest first
			for i = #records, 1, -1 do
				local rec = records[i]
				table.insert(out, {
					text = format_row(rec),
					preview = {
						text = rec.prompt or '',
						ft = 'markdown',
					},
					record = rec,
				})
				-- Yield periodically so the UI stays responsive
				if #out % 200 == 0 then
					ctx.async:yield(out)
					out = {}
				end
			end
		end
		return out
	end

	local function send_directly(record)
		local content = record.prompt or ''
		if content == '' then
			return
		end
		require('KoalaVim.utils.ai.history').append(content, record.agent or 'claude')
		require('sidekick.cli.state').with(function(state)
			local termbufid = state.terminal.buf
			local clear_keys = {
				claude = '\x15',
				codex = '\x15',
				cursor = '\x03',
			}
			local clear_key = clear_keys[state.tool.name] or '\x03'
			vim.api.nvim_chan_send(vim.bo[termbufid].channel, clear_key)
			state.session:send(content)
		end, {
			attach = true,
			filter = {},
			focus = true,
			show = true,
		})
	end

	Snacks.picker({
		title = 'Prompt history (' .. scope .. ')',
		finder = finder,
		format = 'text',
		preview = 'preview',
		win = {
			input = {
				keys = {
					['<c-s>'] = { 'send_directly', mode = { 'n', 'i' } },
				},
			},
		},
		actions = {
			send_directly = function(picker, item)
				picker:close()
				if item and item.record then
					send_directly(item.record)
				end
			end,
		},
		confirm = function(picker, item)
			picker:close()
			if item and item.record then
				require('KoalaVim.utils.ai.general').open_prompt_with(item.record.prompt or '')
			end
		end,
	})
end
```

Note: the duplicated `clear_keys` table is intentional. The picker's send path runs after the original buffer is gone, so we can't rely on `general.lua`'s closure-local `CLEAR_KEYS`. A future task could expose `general.CLEAR_KEYS` and remove the duplication, but YAGNI for now.

- [ ] **Step 2: Manually verify the picker (local scope)**

Make sure you have at least 2-3 records in the current branch's file (use `edit_prompt` a few times).

```vim
:lua require('KoalaVim.utils.ai.history').pick('local')
```

Expected:
- Picker opens with rows like `2026-05-11 14:32 · claude · KoalaVim/master · my first prompt`.
- Preview pane shows the full multi-line prompt.
- Fuzzy typing filters as expected (try typing part of an agent name, part of the prompt body).

- [ ] **Step 3: Verify `<CR>` loads into the edit buffer**

In the picker, select a row and press `<CR>`. Expected:
- The edit_prompt split opens.
- It's prefilled with the historical prompt's full content.
- Closing the buffer sends to the agent (and records a fresh history entry).

- [ ] **Step 4: Verify `<C-s>` sends directly**

Re-open the picker. Select a row and press `<C-s>`. Expected:
- No edit buffer opens.
- The prompt is sent immediately to the attached agent.
- A new history record is appended.

- [ ] **Step 5: Verify workspace and global scopes**

```vim
:lua require('KoalaVim.utils.ai.history').pick('workspace')
:lua require('KoalaVim.utils.ai.history').pick('global')
```

If you only have one branch's data, both will look the same as `local`. To meaningfully test, switch to a different branch, send a prompt, switch back, and run the workspace picker — it should show records from both branches.

- [ ] **Step 6: Verify empty-scope behavior**

```vim
:lua require('KoalaVim.utils.ai.history').pick('local')
```

In a directory with no history (e.g., `:cd /tmp` first). Expected: INFO notify "prompt history: nothing recorded yet". No picker opens.

- [ ] **Step 7: Commit**

```bash
git add lua/KoalaVim/utils/ai/history.lua
git commit -m "feat(ai): snacks picker for prompt history"
```

---

### Task 7: Expose picker wrappers on `general.lua`

**Files:**
- Modify: `lua/KoalaVim/utils/ai/general.lua` (append near the bottom, before `return M`)

- [ ] **Step 1: Add the three wrappers**

In `lua/KoalaVim/utils/ai/general.lua`, append before `return M`:

```lua
function M.pick_prompt_history_local()
	require('KoalaVim.utils.ai.history').pick('local')
end

function M.pick_prompt_history_workspace()
	require('KoalaVim.utils.ai.history').pick('workspace')
end

function M.pick_prompt_history_global()
	require('KoalaVim.utils.ai.history').pick('global')
end
```

- [ ] **Step 2: Manually verify the wrappers**

```vim
:lua require('KoalaVim.utils.ai.general').pick_prompt_history_local()
:lua require('KoalaVim.utils.ai.general').pick_prompt_history_workspace()
:lua require('KoalaVim.utils.ai.general').pick_prompt_history_global()
```

Each should open the same picker as the direct `history.pick(...)` calls in Task 6.

- [ ] **Step 3: Commit**

```bash
git add lua/KoalaVim/utils/ai/general.lua
git commit -m "feat(ai): expose pick_prompt_history wrappers"
```

---

## Out of Scope

These are intentionally not in this plan; revisit if needed later:

- Keymaps for the three picker wrappers (user's call).
- Retention/rotation policy for the JSONL files.
- Cross-machine sharing.
- Dedup of consecutive identical prompts.
