local M = {}

-- Formatting is LazyVim's (format on save, `<leader>uf`/`<leader>uF` toggles, conform + LSP fallback),
-- see utils/lsp.lua for KoalaVim's blacklists (`lsp.format.*` / `lsp.autoformat.*` in kvim.conf).
-- Formatters are declared with conform's `formatters_by_ft` next to each language.
table.insert(M, {
	-- Spec of LazyVim's `lazyvim.util.format` itself, `init` isn't used by LazyVim's own spec.
	-- Must run before the formatters are registered (VeryLazy / lspconfig config).
	'LazyVim/LazyVim',
	init = function()
		require('KoalaVim.utils.lsp').setup_format()
	end,
})

-- Lightweight async formatter runner, format on demand with <leader>F
table.insert(M, {
	'stevearc/conform.nvim',
	-- Don't set `config`, LazyVim errors otherwise (`config = M.setup` warns on format_on_save).
	keys = {
		{
			'<leader>F',
			function()
				LazyVim.format({ force = true })
			end,
			mode = { 'n', 'x' },
			desc = 'Format',
		},
	},
	opts = function(_, opts)
		require('KoalaVim.utils.lsp').conform_blacklist(opts)
	end,
})

return M
