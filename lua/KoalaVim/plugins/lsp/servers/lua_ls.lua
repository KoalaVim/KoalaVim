local M = {}

LSP_SERVERS['lua_ls'] = {
	settings = {
		Lua = {
			telemetry = {
				enable = false,
			},
			hint = {
				enable = true,
			},
		},
	},
}

-- FIXME: `vim.` doesn't work
table.insert(M, {
	'folke/neodev.nvim',
	config = function()
		require('neodev').setup({
			library = {
				plugins = { 'nvim-treesitter', 'plenary.nvim', 'ofirkai.nvim' },
			},
		})
	end,
})

return M
