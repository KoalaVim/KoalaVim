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
		ignore = function(_buf)
			return CODE_DIFF_OPENED
		end,
		code = {
			sign = false,
			width = 'block',
			right_pad = 1,
		},
		heading = {
			sign = false,
			icons = {},
		},
		anti_conceal = {
			-- Do not remove render on current line
			enabled = false,
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

		-- Keep rendering while marking with mouse
		local mouse_visual_active = false
		local drag_key = vim.api.nvim_replace_termcodes('<LeftDrag>', true, false, true)
		local double_click_key = vim.api.nvim_replace_termcodes('<2-LeftMouse>', true, false, true)
		local triple_click_key = vim.api.nvim_replace_termcodes('<3-LeftMouse>', true, false, true)
		local function set_visual_render(enable)
			local state = require('render-markdown.state')
			if not state.config then
				return
			end
			if enable then
				state.config.render_modes = { 'n', 'c', 't', 'v', 'V', '\22' }
			else
				state.config.render_modes = { 'n', 'c', 't' }
			end
			state.cache = {}
		end
		local function mouse_visual_start(feedkey)
			if vim.bo.filetype == 'markdown' then
				mouse_visual_active = true
				set_visual_render(true)
			end
			vim.api.nvim_feedkeys(feedkey, 'in', false)
		end
		vim.keymap.set({ 'n', 'v' }, '<LeftDrag>', function()
			mouse_visual_start(drag_key)
		end)
		vim.keymap.set({ 'n', 'v' }, '<2-LeftMouse>', function()
			mouse_visual_start(double_click_key)
		end)
		vim.keymap.set({ 'n', 'v' }, '<3-LeftMouse>', function()
			mouse_visual_start(triple_click_key)
		end)
		vim.api.nvim_create_autocmd('ModeChanged', {
			pattern = '[vV\x16]*:*',
			callback = function(args)
				vim.schedule(function()
					local mode = vim.fn.mode()
					if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
						if mouse_visual_active then
							mouse_visual_active = false
							set_visual_render(false)
						end
					end
				end)
			end,
		})
	end,
})

table.insert(M, {
	'KoalaVim/checkmate.nvim', -- fork
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
			'<leader>tl',
			function()
				_G._checkmate_cycle_next = function()
					require('checkmate').cycle()
				end
				vim.go.operatorfunc = 'v:lua._checkmate_cycle_next'
				vim.cmd('normal! g@l')
			end,
			ft = 'markdown',
			mode = 'n',
			desc = 'Cycle todo next',
		},
		{ '<leader>tl', '<cmd>Checkmate cycle_next<CR>', ft = 'markdown', mode = 'v', desc = 'Cycle todo next' },
		{
			'<leader>th',
			function()
				_G._checkmate_cycle_prev = function()
					require('checkmate').cycle({ backward = true })
				end
				vim.go.operatorfunc = 'v:lua._checkmate_cycle_prev'
				vim.cmd('normal! g@l')
			end,
			ft = 'markdown',
			mode = 'n',
			desc = 'Cycle todo previous',
		},
		{
			'<leader>th',
			'<cmd>Checkmate cycle_previous<CR>',
			ft = 'markdown',
			mode = 'v',
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
		{
			'<leader>ts',
			function()
				local states = vim.tbl_keys(require('checkmate.config').options.todo_states)
				table.sort(states)
				vim.ui.select(states, { prompt = 'Set todo state' }, function(choice)
					if choice then
						require('checkmate').toggle(choice)
					end
				end)
			end,
			ft = 'markdown',
			mode = { 'n', 'v' },
			desc = 'Select todo state',
		},
		{ '<leader>ta', '<cmd>Checkmate archive<CR>', ft = 'markdown', desc = 'Archive completed todos' },
		{ '<leader>tF', '<cmd>Checkmate select_todo<CR>', ft = 'markdown', desc = 'Select todo (picker)' },
		{ '<leader>tv', '<cmd>Checkmate metadata select_value<CR>', ft = 'markdown', desc = 'Select metadata value' },
	},
	opts = {
		files = { '*.md' },
		keys = false,
		todo_states = {
			unchecked = { marker = '□' },
			checked = { marker = '✔' },
			in_progress = {
				marker = '◐',
				markdown = '.',
				type = 'incomplete',
				order = 50,
			},
			cancelled = {
				marker = '✗',
				markdown = 'c',
				type = 'complete',
				order = 2,
			},
			on_hold = {
				marker = '⏸',
				markdown = '/',
				type = 'inactive',
				order = 100,
			},
		},
	},
})

return M
