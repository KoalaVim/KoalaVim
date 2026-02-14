local M = {}

table.insert(M, {
	'folke/lazydev.nvim',
	-- FIXME: for some reason lazy loading this doesn't work sometimes
	-- ft = 'lua', -- only load on lua files
	opts = {
		library = {
			{ path = '${3rd}/luv/library', words = { 'vim%.uv' } },
			{ path = 'LazyVim', words = { 'LazyVim' } },
			{ path = 'snacks.nvim', words = { 'Snacks' } },
			{ path = 'lazy.nvim', words = { 'LazyVim' } },
			-- { path = 'KoalaVim', words = { 'KoalaVim' } },
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
