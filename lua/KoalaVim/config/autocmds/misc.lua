local api = vim.api

local koala_early_autocmds = api.nvim_create_augroup('koala_early', { clear = true })

api.nvim_create_autocmd('FileType', {
	group = koala_early_autocmds,
	pattern = { 'log' },
	callback = function()
		-- Disable search wrapping for log files
		vim.opt_local.wrapscan = false
	end,
})

vim.filetype.add({
	extension = {
		mdc = 'markdown',
		tmux = 'tmux',
	},
})
