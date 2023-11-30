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

-- Linter and diagnostics
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

-- Type checker
NONE_LS_SRCS['mypy'] = {
	builtins_sources = {
		diagnostics = {
			method = {
				require('KoalaVim.consts').null_ls.methods.DIAGNOSTICS_ON_OPEN,
				require('KoalaVim.consts').null_ls.methods.DIAGNOSTICS_ON_SAVE,
			},
			diagnostics_postprocess = function(diagnostic)
				if diagnostic.code == 'import-not-found' then
					diagnostic.code = 'Missing library stubs (typeshed) or py.typed file'
					diagnostic.severity = vim.diagnostic.severity['INFO']
				end
			end,
		},
	},
}

-- TODO: upgrade tools
-- New tools:
-- https://github.com/mtshiba/pylyzer (not ready yet)

return {}
