LSP_SERVERS['pyright'] = {
	settings = {
		pyright = {
			disableOrganizeImports = true,
			reportMissingModuleSource = 'none',
			reportMissingImports = 'none',
			reportUndefinedVariable = 'none',
		},
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = 'workspace',
				typeCheckingMode = 'off',
				useLibraryCodeForTypes = true,
			},
		},
	},
}

LSP_SERVERS['ruff_lsp'] = {
	on_attach = function(client, buffer)
		LSP_ON_ATTACH(client, buffer)
		client.server_capabilities.hoverProvider = false
	end,
	init_options = {
		settings = {
			args = {},
		},
	},
}

-- TODO: upgrade tools
-- New tools:
-- https://github.com/mtshiba/pylyzer (not ready yet)

return {}
