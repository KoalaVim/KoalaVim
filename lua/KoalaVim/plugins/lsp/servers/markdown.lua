local M = {}

LSP_SERVERS['marksman'] = {}

-- Load ignored words
local path = vim.fn.stdpath('config') .. '/spell/en.utf-8.add'
local words = {}

local fd = io.open(path, 'r')
if fd then
	for word in fd:lines() do
		table.insert(words, word)
	end
	fd:close()
end

LSP_SERVERS['ltex'] = {
	filetypes = { 'bib', 'markdown', 'org', 'plaintex', 'rst', 'rnoweb', 'tex' },
	autostart = false,
	settings = {
		ltex = {
			dictionary = {
				['en-US'] = words,
			},
		},
	},
}

local cmd = require('KoalaVim.utils.cmd')

table.insert(M, {
	'toppair/peek.nvim',
	cmd = 'MarkdownPreviewOpen',
	build = 'deno task --quiet build:fast',
	config = function()
		require('peek').setup({})
		cmd.create('MarkdownPreviewOpen', 'Open markdown preview', require('peek').open, {})
		cmd.create('MarkdownPreviewClose', 'Close markdown preview', require('peek').close, {})
	end,
})

return M
