local M = {}

local api = vim.api

function M.show_history(mode)
	local start_pos = nil
	local end_pos = nil

	if mode == 'v' then
		start_pos = api.nvim_buf_get_mark(0, '<')
		end_pos = api.nvim_buf_get_mark(0, '>')
	elseif mode == 'n' then
		start_pos = api.nvim_buf_get_mark(0, '[')
		end_pos = api.nvim_buf_get_mark(0, ']')
	end

	local start_line = start_pos[1]
	local end_line = end_pos[1]

	api.nvim_command('DiffviewFileHistory -L' .. start_line .. ',' .. end_line .. ':' .. vim.fn.expand('%') .. ' %')
end

local function get_repo_root()
	local handle = io.popen('git rev-parse --show-toplevel 2> /dev/null')
	if not handle then
		return nil
	end
	local repo = handle:read('*l')
	handle:close()
	return repo ~= '' and repo or nil
end

function M.git_dirty_files(repo)
	local cmd = { 'git', '-C', repo, 'diff', '--name-only', 'HEAD' }
	local result = vim.fn.systemlist(cmd)

	return result
end

-- FIXME: optimize
function M.jump_to_git_dirty_file(direction)
	local repo = get_repo_root()
	if not repo then
		vim.notify('Not in a git repo', vim.log.levels.WARN)
		return false
	end

	local files = M.git_dirty_files(repo)
	if #files == 0 then
		vim.notify('No git-dirty files', vim.log.levels.INFO)
		return false
	end

	local current = vim.fn.expand('%:.') -- path relative to repo
	local idx = 0

	for i, f in ipairs(files) do
		if f == current then
			idx = i
			break
		end
	end

	local target
	if direction == 'next' then
		target = files[(idx % #files) + 1]
	else
		local prev_idx = idx - 1
		if prev_idx < 1 then
			prev_idx = #files -- wrap around
		end

		target = files[prev_idx]
	end

	vim.cmd('edit ' .. vim.fn.fnameescape(repo .. '/' .. target))
	return true
end

return M
