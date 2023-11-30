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

NONE_LS_SRCS['stylua'] = {
	builtins_sources = {
		'formatting',
	},
}

return M
