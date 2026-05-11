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

return M
