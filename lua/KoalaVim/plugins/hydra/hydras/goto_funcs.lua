-- TODO: @function.name fallback
-- TODO: change hydras global to system like LazyVim's lspconfig

local name = 'Goto Functions'

HYDRAS[name] = {
	hint = [[
 _j_ _J_ : up
 _k_ _K_ : down
  _<Esc>_
	]],
	config = {
		timeout = 4000,
		hint = {
			border = 'rounded',
		},
	},
	mode = { 'n', 'x' },
	heads = {
		{
			'j',
			function()
				require('nvim-treesitter.textobjects.move').goto_next_start('@function.name')
				require('KoalaVim.utils.misc').center_screen()
			end,
		},
		{
			'J',
			function()
				require('nvim-treesitter.textobjects.move').goto_next_end('@function.outer')
				require('KoalaVim.utils.misc').center_screen()
			end,
		},
		{
			'k',
			function()
				require('nvim-treesitter.textobjects.move').goto_previous_start('@function.name')
				require('KoalaVim.utils.misc').center_screen()
			end,
		},
		{
			'K',
			function()
				require('nvim-treesitter.textobjects.move').goto_previous_end('@function.outer')
				require('KoalaVim.utils.misc').center_screen()
			end,
		},
		--
		{ '<Esc>', nil, { exit = true } },
	},
	custom_bodies = {
		{
			'gj',
			function()
				require('nvim-treesitter.textobjects.move').goto_next_start('@function.name')
				require('KoalaVim.utils.misc').center_screen()
				HYDRAS_OBJS[name]:activate()
			end,
			mode = { 'n', 'x' },
			desc = 'Go down a function',
		},
		{
			'gk',
			function()
				require('nvim-treesitter.textobjects.move').goto_previous_start('@function.name')
				require('KoalaVim.utils.misc').center_screen()
				HYDRAS_OBJS[name]:activate()
			end,
			mode = { 'n', 'x' },
			desc = 'Go up a function',
		},
		{
			'gJ',
			function()
				require('nvim-treesitter.textobjects.move').goto_next_end('@function.outer')
				require('KoalaVim.utils.misc').center_screen()
				HYDRAS_OBJS[name]:activate()
			end,
			mode = { 'n', 'x' },
			desc = 'Go down to an end of a function',
		},
		{
			'gK',
			function()
				require('nvim-treesitter.textobjects.move').goto_previous_end('@function.outer')
				require('KoalaVim.utils.misc').center_screen()
				HYDRAS_OBJS[name]:activate()
			end,
			mode = { 'n', 'x' },
			desc = 'Go up to an end of a function',
		},
	},
}

return {}
