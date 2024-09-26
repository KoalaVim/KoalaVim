local M = {}

local FTS = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }

LSP_SERVERS['vtsls'] = {
	on_attach = LSP_ON_ATTACH,
	on_init = LSP_ON_INIT,
	capabilities = LSP_CAPS,
	settings = {
		typescript = {
			inlayHints = {
				parameterNames = { enabled = 'all' },
				parameterTypes = { enabled = true },
				variableTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				enumMemberValues = { enabled = true },
			},
		},
	},
}

table.insert(M, {
	'yioneko/nvim-vtsls',
	dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
	ft = FTS,
})

-- Linter
NONE_LS_SRCS['eslint_d'] = {
	builtins_sources = {
		'code_actions',
		'diagnostics',
	},
}

CONFORM_FORMATTERS['eslint_d'] = FTS
CONFORM_FORMATTERS['prettierd'] = FTS

return M
