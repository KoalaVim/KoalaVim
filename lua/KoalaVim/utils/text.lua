local M = {}

local api = vim.api

function M.get_current_line_text(mode)
	local current_line = api.nvim_get_current_line()
	local start_pos, end_pos = M.get_range(mode)

	return string.sub(current_line, start_pos[2] + 1, end_pos[2] + 1)
end

function M.get_range(mode)
	local start_pos = { 0, 0 }
	local end_pos = { 0, 0 }
	if mode == 'v' then
		start_pos = api.nvim_buf_get_mark(0, '<')
		end_pos = api.nvim_buf_get_mark(0, '>')
	elseif mode == 'n' then
		start_pos = api.nvim_buf_get_mark(0, '[')
		end_pos = api.nvim_buf_get_mark(0, ']')
	end

	return start_pos, end_pos
end

return M
