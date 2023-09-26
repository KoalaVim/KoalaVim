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

return M
