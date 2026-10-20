local M = {}

-- Diagnostics base config, LazyVim passes `opts.diagnostics` to `vim.diagnostic.config()`.
-- KoalaVim's diagnostics cycle (utils/lsp.lua) overrides only the virtual text/lines on top of it,
-- the initial mode is applied by diagflow's `init` (lsp/general.lua).
table.insert(M, {
	'neovim/nvim-lspconfig',
	opts = function(_, opts)
		local icons = require('KoalaVim.utils.icons')
		local signs_text = {}
		for severity, name in pairs(icons.severity_to_name) do
			signs_text[severity] = icons.diagnostics[name]
		end

		opts.diagnostics = vim.tbl_deep_extend('force', opts.diagnostics or {}, {
			underline = false,
			update_in_insert = false,
			severity_sort = true,
			virtual_text = false, -- Controlled by the diagnostics cycle
			signs = {
				text = signs_text,
			},
		})
	end,
	keys = {
		{
			'<leader>l',
			function()
				require('KoalaVim.utils.lsp').cycle_lsp_diagnostics()
			end,
			desc = 'Cycle between lsp diagnostics mode',
		},
		-- Native LSP UI (replaced lspsaga)
		{ '<F2>', vim.lsp.buf.rename, desc = 'Rename symbos with F2' },
		{ '<F4>', vim.lsp.buf.code_action, desc = 'Code action with F4' },
		{ '<leader>L', vim.diagnostic.open_float, desc = 'show Problem' },
	},
})

return M
