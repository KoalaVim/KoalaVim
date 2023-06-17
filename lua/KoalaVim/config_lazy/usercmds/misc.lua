---@diagnostic disable: assign-type-mismatch
local api = vim.api
local opt = vim.opt

api.nvim_create_user_command('CloseAllButCurrent', function()
	require('KoalaVim.utils.splits').close_all_but_current()
end, {})

api.nvim_create_user_command('CloseBuffersLeft', function()
	api.nvim_command('BufferLineCloseLeft')
end, {})

api.nvim_create_user_command('CloseBuffersRight', function()
	api.nvim_command('BufferLineCloseRight')
end, {})

api.nvim_create_user_command('SetOsClipboard', function()
	opt.clipboard = 'unnamedplus'
end, {})

api.nvim_create_user_command('NoOsClipboard', function()
	opt.clipboard = ''
end, {})

api.nvim_create_user_command('ListKeys', function()
	require('telescope.builtin').keymaps()
end, {})

-- TODO: install SSR
api.nvim_create_user_command('SSR', function()
	require('ssr').open()
end, {})
