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

return M
