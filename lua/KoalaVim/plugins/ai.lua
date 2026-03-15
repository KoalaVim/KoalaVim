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

local ai = require('KoalaVim.utils.ai.general')

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
				keys = {
					-- Using Navigator.nvim to navigate
					nav_left = {
						'<c-h>',
						'<cmd>NavigatorLeft<cr>',
						expr = false,
						desc = 'navigate to the left window',
					},
					nav_down = {
						'<c-j>',
						'<cmd>NavigatorDown<cr>',
						expr = false,
						desc = 'navigate to the below window',
					},
					nav_up = {
						'<c-k>',
						'<cmd>NavigatorUp<cr>',
						expr = false,
						desc = 'navigate to the above window',
					},
					nav_right = {
						'<c-l>',
						'<cmd>NavigatorRight<cr>',
						expr = false,
						desc = 'navigate to the right window',
					},
				},
			},
		},
	},
	keys = {
		{
			'<C-g>',
			function()
				require('KoalaVim.utils.git').show_diff()
			end,
			ft = 'sidekick_terminal',
			desc = 'Open Diff',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'<C-.>',
			'<S-tab>',
			ft = 'sidekick_terminal',
			desc = 'Switch cursor modes',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'<C-e>',
			function()
				ai.edit_prompt()
			end,
			ft = 'sidekick_terminal',
			desc = 'edit prompt in neovim buffer',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			']p',
			function()
				ai.nav_to_prompt('n')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'[p',
			function()
				ai.nav_to_prompt('N')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = { 'n', 't' },
		},
		{
			-- FIXME: apply only in cursor
			'gj',
			function()
				ai.nav_to_prompt('n')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = 'n',
		},
		{
			-- FIXME: apply only in cursor
			'gk',
			function()
				ai.nav_to_prompt('N')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = 'n',
		},
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
			'<leader>ai',
			function()
				-- FIXME: default agent from koalaconfig
				require('sidekick.cli').show({ name = 'cursor' })
			end,
			desc = 'Open/Focus AI',
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
