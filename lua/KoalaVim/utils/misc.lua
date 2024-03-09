local M = {}

local api = vim.api

function M.center_screen()
	api.nvim_feedkeys('zz', 'n', false)
end

function M.restart_nvim()
	local f = io.open(vim.fn.stdpath('data') .. '/restart_kvim', 'w')
	if f ~= nil then
		f:close()
	end
	api.nvim_feedkeys(':wqa\n', 'n', false)
end

return M
