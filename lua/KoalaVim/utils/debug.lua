local M = {}

local lastDebuggedFile = nil
local lastDebuggedArgs = nil

function M._get_last_debugged_file(default)
	return lastDebuggedFile or default
end

function M.choose_file()
	---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
	lastDebuggedFile = vim.fn.input('Path to executable: ', M._get_last_debugged_file('./a.out'), 'file')
	return lastDebuggedFile
end

function M.choose_args()
	---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
	lastDebuggedArgs = vim.fn.input('Enter arguments to run the program with: ', lastDebuggedArgs or '', 'file')
	return vim.split(lastDebuggedArgs, ' ', { trimempty = true })
end

function M.get_session_data()
	-- TODO: save dapui layout
	if package.loaded['dapui'] then
		-- TODO: use common function with dap_closed
		require('dapui').close()
		-- TODO: track debug page and close if needed
		-- vim.api.nvim_command('tabclose $') -- $(last) is the debug page
	end

	return {
		lastDebuggedFile = lastDebuggedFile,
		lastDebuggedArgs = lastDebuggedArgs,
	}
end

function M.restore_session_data(data)
	lastDebuggedFile = data.lastDebuggedFile
	lastDebuggedArgs = data.lastDebuggedArgs
end

function M.init()
	vim.api.nvim_create_user_command('DebugReplOpened', function()
		local win = vim.api.nvim_get_current_win()
		vim.schedule(function()
			M._repl_opened(win)
		end)
	end, {})
end

local repl_info = nil

function M.toggle_repl()
	-- Close last repl win if it was opened already
	if repl_info then
		local did_zoom = require('neo-zoom').did_zoom()
		local zoomed_win = require('neo-zoom').zoom_book[did_zoom[2]]
		if did_zoom[1] and zoomed_win == repl_info.last_win then
			-- Close repl zoom (will call NeoZoomClosed)
			vim.api.nvim_set_current_win(did_zoom[2])
			vim.cmd('NeoZoomToggle')
		end
		repl_info = nil
	else
		repl_info = { orig_win = vim.api.nvim_get_current_win() }
		require('dap').repl.open(nil, 'belowright split | DebugReplOpened')
	end
end

function M._repl_opened(win)
	vim.api.nvim_set_current_win(win)
	vim.cmd('NeoZoomToggle')
	-- vim.api.nvim_feedkeys('i', 'n', false)
	repl_info.last_win = win

	-- Auto close opened repl on zoom out/quit
	vim.api.nvim_create_autocmd('User', {
		pattern = 'NeoZoomClosed',
		once = true,
		callback = function(events)
			if events.data.original_win == win then
				vim.api.nvim_win_close(win, true)
				vim.api.nvim_set_current_win(repl_info.orig_win)
				repl_info = nil
			end
		end,
	})
end

return M
