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

local function format_row(record)
	local time_str = os.date('%Y-%m-%d %H:%M', record.ts or 0)
	local first_line = (record.prompt or ''):match('[^\n]*') or ''
	if #first_line > 200 then
		first_line = first_line:sub(1, 197) .. '...'
	end
	return string.format('%s │ %s', time_str, first_line)
end

local function format_preview(record)
	local time_str = os.date('%Y-%m-%d %H:%M:%S', record.ts or 0)
	local workspace = vim.fn.fnamemodify(record.cwd or '', ':t')
	return table.concat({
		'# Prompt',
		'',
		'- **Time:**      ' .. time_str,
		'- **Agent:**     ' .. (record.agent or '?'),
		'- **Workspace:** ' .. workspace,
		'- **Branch:**    ' .. (record.branch or 'no-branch'),
		'- **Cwd:**       ' .. (record.cwd or ''),
		'',
		'---',
		'',
		record.prompt or '',
	}, '\n')
end

--- Open a snacks picker over the given scope. Selecting a prompt with <CR>
--- opens an editable buffer; <C-s> sends it directly. <C-l>/<C-w>/<C-g>
--- switch the picker between local/workspace/global scopes.
---@param scope 'local' | 'workspace' | 'global'
function M.pick(scope)
	local files = M.list_files(scope)
	if #files == 0 then
		vim.notify(
			('prompt history (%s): nothing recorded yet'):format(scope),
			vim.log.levels.INFO
		)
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
						text = format_preview(rec),
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

	local function switch_scope(picker, new_scope)
		if new_scope == scope then
			return
		end
		picker:close()
		vim.schedule(function()
			M.pick(new_scope)
		end)
	end

	Snacks.picker({
		title = ('Prompt history [%s] — <C-l>local <C-w>workspace <C-g>global'):format(scope),
		finder = finder,
		format = 'text',
		preview = 'preview',
		win = {
			input = {
				keys = {
					['<c-s>'] = { 'send_directly', mode = { 'n', 'i' } },
					['<c-l>'] = { 'scope_local', mode = { 'n', 'i' } },
					['<c-w>'] = { 'scope_workspace', mode = { 'n', 'i' } },
					['<c-g>'] = { 'scope_global', mode = { 'n', 'i' } },
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
			scope_local = function(picker)
				switch_scope(picker, 'local')
			end,
			scope_workspace = function(picker)
				switch_scope(picker, 'workspace')
			end,
			scope_global = function(picker)
				switch_scope(picker, 'global')
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

return M
