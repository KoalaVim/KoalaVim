local M = {}

local FTS = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }

table.insert(M, {
	'pmizio/typescript-tools.nvim',
	dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
	ft = FTS,
	config = function()
		require('typescript-tools').setup({
			on_attach = LSP_ON_ATTACH,
			on_init = LSP_ON_INIT,
			capabilities = LSP_CAPS,
			settings = {
				jsx_close_tag = { enable = true },
				tsserver_file_preferences = {
					includeInlayEnumMemberValueHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all';
					includeInlayParameterNameHintsWhenArgumentMatchesName = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayVariableTypeHints = true,
				},
			},
		})
	end,
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
