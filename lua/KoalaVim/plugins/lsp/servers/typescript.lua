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

-- vtsls or tsc (tsgo) is picked by `vim.g.lazyvim_ts_lsp`, set from `lsp.tsgo.enabled` in `config/options.lua`
table.insert(M, {
	'neovim/nvim-lspconfig',
	opts = function(_, opts)
		local conf = require('KoalaVim').conf.lsp

		opts.servers.vtsls = vim.tbl_deep_extend('force', opts.servers.vtsls or {}, {
			settings = {
				typescript = {
					inlayHints = inlay_hints,
				},
			},
		})

		if conf.vtsls.max_memory and conf.vtsls.max_memory ~= vim.NIL then
			opts.servers.vtsls.settings.typescript.tsserver = {
				maxTsServerMemory = conf.vtsls.max_memory,
			}
		end

		opts.servers.tsc = vim.tbl_deep_extend('force', opts.servers.tsc or {}, {
			settings = {
				['js/ts'] = {
					inlayHints = inlay_hints,
				},
			},
		})

		-- nvim-lspconfig (pinned) has no `tsc` config yet
		opts.servers.tsc.cmd = { 'tsc', '--lsp', '--stdio' }
		opts.servers.tsc.root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' }

		if conf.tsgo.enabled and vim.fn.executable('tsc') == 0 then
			require('KoalaVim.health').warn('[tsgo] enabled but tsc is not installed. Run :MasonInstall tsc')
		end
	end,
})

-- Wrapper for the vtsls TypeScript LSP with extra commands and features
table.insert(M, {
	'yioneko/nvim-vtsls',
	dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
	ft = FTS,
})

-- Formatters (eslint_d fixes, then prettierd). LazyVim's `formatting.prettier`/`linting.eslint` extras aren't used
local formatters_by_ft = {}
for _, ft in ipairs(FTS) do
	formatters_by_ft[ft] = { 'eslint_d', 'prettierd' }
end

table.insert(M, {
	'stevearc/conform.nvim',
	opts = { formatters_by_ft = formatters_by_ft },
})

table.insert(M, {
	'mason-org/mason.nvim',
	opts = { ensure_installed = { 'eslint_d', 'prettierd' } },
})

return M
