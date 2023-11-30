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

-- For plugins
LSP_SERVERS['pylsp'] = {
	settings = {
		pylsp = {
			plugins = {
				-- Auto import code actions
				rope_autoimport = {
					enabled = true,
					completions = { enabled = false },
					code_actions = { enabled = true },
				},

				-- Disable LSP plugins
				autopep8 = { enabled = false },
				flake8 = { enabled = false },
				jedi_completion = { enabled = false },
				jedi_definition = { enabled = false },
				jedi_hover = { enabled = false },
				jedi_references = { enabled = false },
				jedi_signature_help = { enabled = false },
				jedi_symbols = { enabled = false },
				mccabe = { enabled = false },
				preload = { enabled = false },
				pycodestyle = { enabled = false },
				pydocstyle = { enabled = false },
				pyflakes = { enabled = false },
				pylint = { enabled = false },
				rope_completion = { enabled = false },
				yapf = { enabled = false },
			},
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
