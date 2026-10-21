local M = {}

local kkeys = require('KoalaVim.utils.map').kkeys

-- Toggleable floating/split terminals with multi-instance support (koala flavor).
-- The lazyvim flavor uses LazyVim's snacks terminal (`<c-/>`).
table.insert(M, {
	'akinsho/toggleterm.nvim',
	enabled = function()
		return require('KoalaVim.flavor').is('koala')
	end,
	keys = kkeys({
		{
			'<C-t>',
			function()
				toggle_or_open_terminal()
			end,
			mode = { 'n', 't', 'v' },
			desc = 'toggle all terminals',
		},
		{
			'<M-e>',
			function()
				if vim.bo.filetype == 'sidekick_terminal' then
					require('KoalaVim.utils.splits').smart_split('vertical')
				else
					open_new_terminal('vertical')
				end
			end,
			mode = 't',
			desc = 'Split terminal',
		},
	}),
	config = function()
		local toggle_term = require('toggleterm')
		toggle_term.setup({
			open_mapping = [[<Nop>]],
			insert_mappings = false,
			terminal_mappings = false,
			direction = 'horizontal',
			size = 20,
			shade_terminals = false,
			highlights = {
				Normal = {
					guibg = '#000000',
					guifg = '#ffffff',
				},
			},
		})

		local terms = require('toggleterm.terminal')

		toggle_or_open_terminal = function(direction)
			-- print("toggle " .. #terms.get_all() .. " hidden " .. #terms.get_all(true))
			if #terms.get_all() == 0 then
				open_new_terminal(direction)
			else
				toggle_term.toggle_all(true)
			end
		end

		open_new_terminal = function(direction)
			-- Flip directions...
			if direction == 'horizontal' then
				direction = 'vertical'
			else
				direction = 'horizontal'
			end
			local ft = vim.api.nvim_buf_get_option(0, 'filetype')
			local dir = vim.fn.expand('%:p:h')
			if ft == 'toggleterm' then
				dir = string.gsub(string.gsub(vim.fn.expand('%:h:h:h'), 'term://', ''), '//.+', '')
			end
			-- Fallback to cwd when the buffer's dir isn't a real directory
			-- (e.g. sidekick terminal buffers have scheme-like names).
			if vim.fn.isdirectory(dir) == 0 then
				dir = vim.fn.getcwd()
			end

			local term = terms.Terminal:new({ id = #terms.get_all() + 1, dir = dir, direction = direction })
			term:open(nil, direction, true)
		end
	end,
	dependencies = {
		'chomosuke/term-edit.nvim',
	},
})

-- Vim-style editing at the shell prompt, for both flavors.
-- Koala flavor loads it with toggleterm, lazyvim flavor loads it when a terminal opens.
table.insert(M, {
	'chomosuke/term-edit.nvim',
	lazy = true,
	event = require('KoalaVim.flavor').is('lazyvim') and 'TermOpen' or nil,
	config = function()
		require('term-edit').setup({
			prompt_end = '%$ ',
		})
	end,
})

-- Split a sidekick terminal in terminal mode, toggleterm's key does it in the koala flavor
table.insert(M, {
	'folke/snacks.nvim',
	keys = kkeys(require('KoalaVim.flavor').is('lazyvim') and {
		{
			'<M-e>',
			function()
				if vim.bo.filetype == 'sidekick_terminal' then
					require('KoalaVim.utils.splits').smart_split('vertical')
				end
			end,
			mode = 't',
			desc = 'Split terminal',
		},
	} or {}),
})

return M
