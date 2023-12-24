local api = vim.api
local opt_local = vim.opt_local

local usercmd = require('KoalaVim.utils.cmd')

usercmd.create('PrettifyJson', 'Format json', function()
	api.nvim_exec(':%!python3 -m json.tool --sort-keys --indent 2', false)
	opt_local.filetype = 'jsonc'
end, {})

usercmd.create('CompactJson', 'Format json to compact', function()
	api.nvim_exec(':%!python3 -m json.tool --compact', false)
	opt_local.filetype = 'jsonc'
end, {})

usercmd.create('ConvertToSpaces', 'Convert tabs to spaces', function()
	vim.bo.expandtab = true
	vim.cmd('retab')
end, {})

usercmd.create('ConvertToTabs', 'Convert spaces to tabs', function()
	vim.bo.expandtab = false
	vim.cmd('retab')
end, {})

usercmd.create('BreakLines', 'Break lines', function()
	vim.cmd('%!fmt -s -w 300')
end, {})
