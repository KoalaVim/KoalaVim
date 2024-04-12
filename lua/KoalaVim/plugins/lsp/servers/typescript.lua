local M = {}

table.insert(M, {
	'pmizio/typescript-tools.nvim',
	dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
	ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
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
		'formatting',
		'code_actions',
		'diagnostics',
	},
}

-- Formatter
NONE_LS_SRCS['prettierd'] = {
	builtins_sources = { 'formatting' },
}

return M
