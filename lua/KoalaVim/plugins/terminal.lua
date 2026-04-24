local M = {}

-- TODO: fix this annoying bug
--		reproduce:	1. Open terminal (C-t)
--					2. Split it (M-e) twice
--					3. Close all (M-q) * 3
--					4. Reopen terminal, will show term2 instead of 1 and continue to create term2
-- Toggleable floating/split terminals with multi-instance support.
-- Bundles term-edit.nvim for vim-style editing at the shell prompt.
table.insert(M, {
	'akinsho/toggleterm.nvim',
	keys = {
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
				open_new_terminal('vertical')
			end,
			mode = 't',
			desc = 'Split terminal',
		},
	},
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
				-- TODO: this should open in the same dir as the term but it doesn't work
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
		config = function()
			require('term-edit').setup({
				prompt_end = '%$ ',
			})
		end,
	},
})

return M
