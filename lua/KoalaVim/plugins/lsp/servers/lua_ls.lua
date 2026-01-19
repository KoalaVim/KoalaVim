local M = {}

table.insert(M, {
	'folke/lazydev.nvim',
	ft = 'lua', -- only load on lua files
	opts = {
		library = {
			-- See the configuration section for more details
			-- Load luvit types when the `vim.uv` word is found
			{ path = '${3rd}/luv/library', words = { 'vim%.uv' } },
		},
	},
})

LSP_SERVERS['lua_ls'] = {
	settings = {
		Lua = {
			telemetry = {
				enable = false,
			},
			hint = {
				enable = true,
			},
			workspace = {
				checkThirdParty = false,
			},
		},
	},
}

CONFORM_FORMATTERS['stylua'] = { 'lua' }

return M
