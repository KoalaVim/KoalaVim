local M = {}

-- TODO: check on https://github.com/mtshiba/pylyzer
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
	dont_format = true, -- Format through 'ruff' cli. async formatting with this lsp is broken. (deletes code)
	on_attach = function(client, buffer)
		LSP_ON_ATTACH_NO_HOVER(client, buffer)
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
			method = require('KoalaVim.consts').null_ls.methods.DIAGNOSTICS_ON_SAVE,
			diagnostics_postprocess = function(diagnostic)
				if diagnostic.code == 'import-not-found' or diagnostic.code == 'import-untyped' then
					diagnostic.code = 'Missing library stubs (typeshed) or py.typed file'
					diagnostic.severity = vim.diagnostic.severity['INFO']
				end
			end,
		},
	},
	with = {
		extra_args = {
			'--check-untyped-defs',
		},
	},
}

CONFORM_FORMATTERS['black'] = { 'python' }
CONFORM_FORMATTERS['ruff_format'] = { 'python', mason = 'ruff' }

-- TODO: upgrade tools
-- New tools:
-- https://github.com/mtshiba/pylyzer (not ready yet)

return M
