local M = {}

function M.set_buffer_opt(buffer, name, value)
	-- Setting an option takes *significantly* more time than reading it.
	-- This wrapper function only sets the option if the new value differs
	-- from the current value.
	local current = vim.api.nvim_buf_get_option(buffer, name)
	if value ~= current then
		vim.api.nvim_buf_set_option(buffer, name, value)
	end
end

return M
