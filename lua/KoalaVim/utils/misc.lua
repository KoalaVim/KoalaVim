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

	-- FIXME: move to possession.nvim
	local sidekick_ok, sidekick_cli = pcall(require, 'sidekick.cli')
	if sidekick_ok then
		sidekick_cli.close()
		vim.schedule(function()
			api.nvim_feedkeys(':wqa\n', 'n', false)
		end)
		return
	end

	api.nvim_feedkeys(':wqa\n', 'n', false)
end

return M
