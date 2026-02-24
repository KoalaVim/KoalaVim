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
	dont_setup = true, -- Disable for now
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
	enabled = false,
	cmd = 'MarkdownPreviewOpen',
	build = 'deno task --quiet build:fast',
	config = function()
		require('peek').setup({})
		cmd.create('MarkdownPreviewOpen', 'Open markdown preview', require('peek').open, {})
		cmd.create('MarkdownPreviewClose', 'Close markdown preview', require('peek').close, {})
	end,
})

table.insert(M, {
	'iamcco/markdown-preview.nvim',
	cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
	build = function()
		require('lazy').load({ plugins = { 'markdown-preview.nvim' } })
		vim.fn['mkdp#util#install']()
	end,
	keys = {
		{
			'<leader>uP',
			ft = 'markdown',
			'<cmd>MarkdownPreviewToggle<cr>',
			desc = 'Markdown Preview',
		},
	},
	config = function()
		vim.cmd([[do FileType]])
	end,
})

table.insert(M, {
	'MeanderingProgrammer/render-markdown.nvim',
	opts = {
		code = {
			sign = false,
			width = 'block',
			right_pad = 1,
		},
		heading = {
			sign = false,
			icons = {},
		},
	},
	ft = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion' },
	keys = {
		{
			'<leader>up',
			ft = 'markdown',
			function()
				require('render-markdown').toggle()
			end,
			desc = 'Markdown Render Preview',
		},
	},
	config = function(_, opts)
		require('render-markdown').setup(opts)
	end,
})

return M
