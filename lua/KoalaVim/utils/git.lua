local M = {}

local api = vim.api

function M.show_status()
	if vim.env.NEOGIT then
		require('neogit').open({ kind = 'floating' })
	else
		vim.cmd('G')
	end
end

function M.show_tree(args)
	vim.cmd('Flog -- ' .. args)
end

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

	local file_path = vim.fn.fnameescape(repo .. '/' .. target)

	-- Go to next/prev hunk after jump
	vim.api.nvim_create_autocmd('BufEnter', {
		pattern = file_path,
		once = true,
		callback = vim.schedule_wrap(function()
			print('heyyyyyyyy')
			-- Go to end/start and navigate to first hunk
			api.nvim_feedkeys(direction == 'next' and 'gg' or 'G', 'n', false)

			-- Schedule to run after feedkeys positions the cursor at gg/G
			vim.defer_fn(function()
				require('gitsigns.actions').nav_hunk(
					direction,
					{ navigation_message = false, target = 'all', wrap = false }
				)
			end, 30)
		end),
	})

	vim.cmd('edit ' .. file_path)

	return true
end

--- XXX: not used for now
--- Navigate to the next/prev git hunk across files.
--- First attempts to jump to the next hunk in the current buffer. If the cursor
--- didn't move (no more hunks in this direction), it jumps to the next dirty file
--- and navigates to its first/last hunk depending on direction.
---@param direction 'next'|'prev'
function M.nav_to_next_hunk_or_file(direction)
	local DEFER_VAL = 30
	local current_line = api.nvim_get_current_line()

	-- Schedule to avoid running during a textlock (e.g. triggered from an expr mapping)
	vim.schedule(function()
		require('gitsigns.actions').nav_hunk(direction, { navigation_message = false, target = 'all', wrap = false })

		-- Defer to let gitsigns finish the hunk navigation before checking the result
		vim.defer_fn(function()
			-- If the cursor didn't move, there are no more hunks in this file
			if api.nvim_get_current_line() == current_line then
				-- Jump to the next dirty file and navigate to its first/last hunk
				require('KoalaVim.utils.git').jump_to_git_dirty_file(direction)
			end
		end, DEFER_VAL)
	end)
end

return M
