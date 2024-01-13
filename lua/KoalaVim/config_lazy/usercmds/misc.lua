---@diagnostic disable: assign-type-mismatch
local api = vim.api
local opt = vim.opt

local usercmd = require('KoalaVim.utils.cmd')

usercmd.create('CloseAllButCurrent', 'Close all buffers but current', function()
	require('KoalaVim.utils.splits').close_all_but_current()
end, {})

usercmd.create('CloseBuffersLeft', 'Close all left buffers', function()
	api.nvim_command('BufferLineCloseLeft')
end, {})

usercmd.create('CloseBuffersRight', 'Close all right buffers', function()
	api.nvim_command('BufferLineCloseRight')
end, {})

usercmd.create('SetOsClipboard', 'Set vim clipboard to OS clipboard', function()
	opt.clipboard = 'unnamedplus'
end, {})

usercmd.create('NoOsClipboard', 'Set vim clipboard to default', function()
	opt.clipboard = ''
end, {})

usercmd.create('ListKeys', 'List all the keys', function()
	require('telescope.builtin').keymaps()
end, {})

usercmd.create('ListCmds', 'List the cmds', function()
	require('telescope.builtin').commands()
end, {})

usercmd.create('KoalaUpdate', 'Update KoalaVim', function()
	require('KoalaVim.utils.update_checker').update()
end)
