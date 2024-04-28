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
			workspace = {
				checkThirdParty = false,
			},
		},
	},
}

CONFORM_FORMATTERS['stylua'] = { 'lua' }

return M
