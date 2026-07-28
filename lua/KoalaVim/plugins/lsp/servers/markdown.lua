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

-- Markdown preview in a webview window powered by Deno
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

-- Browser-based live markdown preview with GitHub-flavored rendering
table.insert(M, {
	'iamcco/markdown-preview.nvim',
	cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
	build = function()
		require('lazy').load({ plugins = { 'markdown-preview.nvim' } })
		vim.fn['mkdp#util#install']()
	end,
	keys = {
		{
			'<leader>up',
			ft = 'markdown',
			'<cmd>MarkdownPreviewToggle<cr>',
			desc = 'Markdown Preview',
		},
	},
	config = function()
		vim.cmd([[do FileType]])
	end,
})

-- Render markdown inside the buffer (headings, code blocks, tables, etc.)
table.insert(M, {
	'MeanderingProgrammer/render-markdown.nvim',
	opts = {
		enabled = true,
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
			'<M-p>',
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

table.insert(M, {
	'bngarren/checkmate.nvim',
	ft = 'markdown',
	keys = {
		{
			'<leader>tt',
			'<cmd>Checkmate toggle<CR>',
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Toggle todo item',
		},
		{
			'<leader>tc',
			'<cmd>Checkmate check<CR>',
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Check todo item',
		},
		{
			'<leader>tu',
			'<cmd>Checkmate uncheck<CR>',
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Uncheck todo item',
		},
		{
			'<leader>t=',
			'<cmd>Checkmate cycle_next<CR>',
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Cycle todo next',
		},
		{
			'<leader>t-',
			'<cmd>Checkmate cycle_previous<CR>',
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Cycle todo previous',
		},
		{ '<leader>tn', '<cmd>Checkmate create<CR>', ft = 'markdown', mode = { 'n', 'v' }, desc = 'Create todo item' },
		{
			'<leader>tr',
			'<cmd>Checkmate remove<CR>',
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Remove todo marker',
		},
		{
			'<leader>tR',
			'<cmd>Checkmate remove_all_metadata<CR>',
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Remove all metadata',
		},
		{ '<leader>ta', '<cmd>Checkmate archive<CR>', ft = 'markdown', desc = 'Archive completed todos' },
		{ '<leader>tF', '<cmd>Checkmate select_todo<CR>', ft = 'markdown', desc = 'Select todo (picker)' },
		{ '<leader>tv', '<cmd>Checkmate metadata select_value<CR>', ft = 'markdown', desc = 'Select metadata value' },
	},
	opts = {
		files = { '*.md' },
		keys = false,
	},
})

return M
