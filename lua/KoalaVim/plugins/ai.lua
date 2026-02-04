local M = {}

table.insert(M, {
	-- ChatGPT from nvim
	'jackMort/ChatGPT.nvim',
	cmd = { 'ChatGPT', 'ChatGPTActAs', 'ChatGPTRunCustomCodeAction', 'ChatGPTEditWithInstructions' },
	config = function()
		require('chatgpt').setup()
	end,
	dependencies = {
		'MunifTanjim/nui.nvim',
		'nvim-lua/plenary.nvim',
		'nvim-telescope/telescope.nvim',
	},
})

table.insert(M, {
	-- Quick ChatGPT from nvim, <C-a> in insert mode or :AI in selection
	'aduros/ai.vim',
	cmd = 'AI',
	init = function()
		vim.g.ai_no_mappings = true
	end,
})

table.insert(M, {
	'folke/sidekick.nvim',
	opts = {
		cli = {
			---@class sidekick.win.Opts
			win = {
				split = {
					width = 0,
					height = 0,
				},
			},
		},
	},
	keys = {
		{
			'<leader>uN',
			function()
				require('sidekick.nes').toggle()
			end,
			desc = 'Toggle sidekick NES',
		},
		-- nes is also useful in normal mode
		-- FIXME: enable 'nes'
		-- { '<tab>', LazyVim.cmp.map({ 'ai_nes' }, '<tab>'), mode = { 'n' }, expr = true },
		{ '<leader>a', '', desc = '+ai', mode = { 'n', 'v' } },
		{
			'<c-.>',
			function()
				require('sidekick.cli').toggle()
			end,
			desc = 'Sidekick Toggle',
			mode = { 'n', 't', 'i', 'x' },
		},
		{
			'<leader>aa',
			function()
				require('sidekick.cli').toggle()
			end,
			desc = 'Sidekick Toggle CLI',
		},
		{
			'<leader>as',
			function()
				require('sidekick.cli').select()
			end,
			-- Or to select only installed tools:
			-- require("sidekick.cli").select({ filter = { installed = true } })
			desc = 'Select CLI',
		},
		{
			'<leader>ad',
			function()
				require('sidekick.cli').close()
			end,
			desc = 'Detach a CLI Session',
		},
		{
			'<leader>at',
			function()
				require('sidekick.cli').send({ msg = '{this}' })
			end,
			mode = { 'x', 'n' },
			desc = 'Send This',
		},
		{
			'<leader>af',
			function()
				require('sidekick.cli').send({ msg = '{file}' })
			end,
			desc = 'Send File',
		},
		{
			'<leader>av',
			function()
				require('sidekick.cli').send({ msg = '{selection}' })
			end,
			mode = { 'x' },
			desc = 'Send Visual Selection',
		},
		{
			'<leader>ap',
			function()
				require('sidekick.cli').prompt()
			end,
			mode = { 'n', 'x' },
			desc = 'Sidekick Select Prompt',
		},
	},
})

return M
