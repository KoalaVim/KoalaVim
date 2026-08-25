local M = {}

local FTS = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }

local inlay_hints = {
	parameterNames = { enabled = 'all' },
	parameterTypes = { enabled = true },
	variableTypes = { enabled = true },
	propertyDeclarationTypes = { enabled = true },
	functionLikeReturnTypes = { enabled = true },
	enumMemberValues = { enabled = true },
}

table.insert(LSP_LAZY_SERVERS, function()
	local conf = require('KoalaVim').conf.lsp

	local opts = {
		on_attach = LSP_ON_ATTACH,
		on_init = LSP_ON_INIT,
		capabilities = LSP_CAPS,
		settings = {
			typescript = {
				inlayHints = inlay_hints,
			},
		},
	}

	if conf.tsgo.enabled then
		if vim.fn.executable('tsgo') == 0 then
			require('KoalaVim.health').warn('[tsgo] enabled but tsgo is not installed. Run :MasonInstall tsgo')
		end
		return 'tsgo', opts
	end

	if conf.vtsls.max_memory and conf.vtsls.max_memory ~= vim.NIL then
		opts.settings.typescript.tsserver = {
			maxTsServerMemory = conf.vtsls.max_memory,
		}
	end

	return 'vtsls', opts
end)

-- Wrapper for the vtsls TypeScript LSP with extra commands and features
table.insert(M, {
	'yioneko/nvim-vtsls',
	dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
	ft = FTS,
})

-- Linter
-- NONE_LS_SRCS['eslint_d'] = {
-- 	builtins_sources = {
-- 		'code_actions',
-- 		'diagnostics',
-- 	},
-- }

CONFORM_FORMATTERS['eslint_d'] = FTS
CONFORM_FORMATTERS['prettierd'] = FTS

return M
