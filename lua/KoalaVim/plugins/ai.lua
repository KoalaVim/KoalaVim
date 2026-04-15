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

local with_default_tool = ai.with_default_tool

table.insert(M, {
	'ofirgall/sidekick.nvim', --fork
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
			'<C-d>',
			function()
				require('KoalaVim.utils.git').show_diff()
			end,
			ft = 'sidekick_terminal',
			desc = 'Open Diff',
			mode = { 'n', 't' },
		},
		{
			'<C-g>',
			function()
				require('KoalaVim.utils.git').show_status()
			end,
			ft = 'sidekick_terminal',
			desc = 'Open Git Status',
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
			'<C-e>',
			function()
				ai.edit_prompt()
			end,
			ft = 'sidekick_terminal',
			desc = 'edit prompt in neovim buffer',
			mode = { 'n', 't' },
		},
		{
			']p',
			function()
				ai.nav_to_prompt('n')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = { 'n', 't' },
		},
		{
			'[p',
			function()
				ai.nav_to_prompt('N')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = { 'n', 't' },
		},
		{
			'gj',
			function()
				ai.nav_to_prompt('n')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = 'n',
		},
		{
			'gk',
			function()
				ai.nav_to_prompt('N')
			end,
			ft = 'sidekick_terminal',
			desc = 'go to next prompt',
			mode = 'n',
		},
		{
			'<C-s>',
			function()
				ai.toggle_max()
			end,
			ft = 'sidekick_terminal',
			desc = 'Toggle max/half size of sidekick terminal',
			mode = { 'n', 't' },
		},
		{
			'<M-z>',
			function()
				ai.zoom_sidekick()
			end,
			ft = 'sidekick_terminal',
			desc = 'Zoom sidekick terminal in a new tabpage',
			mode = { 'n', 't' },
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
				with_default_tool(require('sidekick.cli').toggle)
			end,
			desc = 'Sidekick Toggle',
			mode = { 'n', 't', 'i', 'x' },
		},
		{
			'<M-a>',
			function()
				with_default_tool(require('sidekick.cli').toggle)
			end,
			-- ft = 'sidekick_terminal',
			desc = 'Zoom sidekick terminal in a new tabpage',
			mode = { 'n', 't' },
		},
		{
			'<leader>ai',
			function()
				with_default_tool(require('sidekick.cli').show)
			end,
			desc = 'Open/Focus AI',
		},
		{
			'<leader>aa',
			function()
				with_default_tool(require('sidekick.cli').toggle)
			end,
			desc = 'Sidekick Toggle CLI',
		},
		{
			'<leader>as',
			function()
				require('sidekick.cli').select({
					filter = { installed = true },
					cb = function(state)
						if state then
							ai.set_default_tool(state.tool.name)
							require('sidekick.cli').show({ name = state.tool.name })
						end
					end,
				})
			end,
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
				with_default_tool(require('sidekick.cli').send, { msg = '{this}' })
			end,
			mode = { 'x', 'n' },
			desc = 'Send This',
		},
		{
			'<leader>af',
			function()
				with_default_tool(require('sidekick.cli').send, { msg = '{file}' })
			end,
			desc = 'Send File',
		},
		{
			'<leader>av',
			function()
				with_default_tool(require('sidekick.cli').send, { msg = '{selection}' })
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
