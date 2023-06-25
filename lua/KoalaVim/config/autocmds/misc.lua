local api = vim.api

local koala_early_autocmds = api.nvim_create_augroup('koala', { clear = true })

api.nvim_create_autocmd('FileType', {
	group = koala_early_autocmds,
	pattern = { 'log' },
	callback = function()
		-- Disable search wrapping for log files
		vim.opt_local.wrapscan = false
	end,
})
