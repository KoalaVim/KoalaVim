local M = {}

local function organize_imports()
	local params = {
		command = '_typescript.organizeImports',
		arguments = { vim.api.nvim_buf_get_name(0) },
		title = '',
	}

	vim.lsp.buf.execute_command(params)
end

LSP_SERVERS['tsserver'] = {
	settings = {
		javascript = {
			inlayHints = {
				includeInlayEnumMemberValueHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all';
				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayVariableTypeHints = true,
			},
		},
		typescript = {
			inlayHints = {
				includeInlayEnumMemberValueHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all';
				includeInlayParameterNameHintsWhenArgumentMatchesName = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayVariableTypeHints = true,
			},
		},
	},
	commands = {
		OrganizeImports = { organize_imports, description = 'Organize Imports' },
	},
}

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
