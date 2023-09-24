local api = vim.api

local koala_autocmds = api.nvim_create_augroup('koala_lazy', { clear = true })

-- Highlight on yank
api.nvim_create_autocmd('TextYankPost', {
	group = koala_autocmds,
	pattern = '*',
	callback = function()
		vim.highlight.on_yank({ timeout = 350, higroup = 'Visual' })
	end,
})

-- Auto spell files
api.nvim_create_autocmd('FileType', {
	group = koala_autocmds,
	pattern = { 'gitcommit', 'markdown' },
	callback = function()
		vim.opt_local.spell = true
	end,
})

-- Small quickfix
local QUICKFIX_HEIGHT = 6
api.nvim_create_autocmd('FileType', {
	group = koala_autocmds,
	pattern = { 'qf' },
	callback = function()
		api.nvim_win_set_height(0, QUICKFIX_HEIGHT)
	end,
})

-- Auto set .tmux filetype
api.nvim_create_autocmd('BufEnter', {
	group = koala_autocmds,
	pattern = '*.tmux',
	callback = function(events)
		api.nvim_buf_set_option(events.buf, 'filetype', 'tmux')
	end,
})

-- Vertical help/man
api.nvim_create_autocmd('FileType', {
	group = koala_autocmds,
	pattern = { 'help', 'man' },
	callback = function()
		-- TODO: detect if should be vertical or horziontal
		vim.cmd('wincmd L')
	end,
})

-- Show absolute line numbers in insert mode
api.nvim_create_autocmd('InsertEnter', {
	group = koala_autocmds,
	callback = function()
		vim.wo.relativenumber = false
	end,
})

api.nvim_create_autocmd('InsertLeave', {
	group = koala_autocmds,
	callback = function()
		vim.wo.relativenumber = true
	end,
})

-- Close nvim if last buffer is NvimTree
api.nvim_create_autocmd('BufEnter', {
	group = koala_autocmds,
	callback = function()
		local get_all_non_floating_wins = require('KoalaVim.utils.windows').get_all_non_floating_wins
		local last_buf_ft = api.nvim_buf_get_option(0, 'filetype')
		if last_buf_ft == 'NvimTree' and #get_all_non_floating_wins() == 1 then
			vim.cmd('quit')
		end
	end,
})
