local M = {}

-- gopls, goimports/gofumpt, golangci-lint and dap-go come from LazyVim's go extra
table.insert(M, {
	'neovim/nvim-lspconfig',
	opts = {
		servers = {
			gopls = {
				-- The extra re-adds the semantic tokens that KoalaVim disables for all servers
				init_options = { semanticTokens = false },
			},
		},
	},
})

-- Rich Go development tools: gopls config, codelens, tests, refactoring helpers
table.insert(M, {
	'ray-x/go.nvim',
	enabled = false,
	dependencies = {
		'ray-x/guihua.lua',
		'neovim/nvim-lspconfig',
	},
	ft = { 'go', 'gomod' },
	build = ':lua require("go.install").update_all_sync()',
	config = function()
		require('go').setup({
			-- No keymaps
			lsp_keymaps = false,
			lsp_codelens = false,
			dap_debug_keymap = false,
			textobjects = false,
			lsp_on_attach = false, -- LazyVim's go extra configures gopls
			lsp_diag_hdlr = false, -- Disable go.nvim diagnostics viewer
			lsp_inlay_hints = {
				enable = false, -- Using inlay-hints.nvim instead
			},
			lsp_cfg = false,
		})

		local map_buffer = require('KoalaVim.utils.map').map_buffer
		local kmap_buffer = require('KoalaVim.utils.map').kmap_buffer
		local add_new_line = 'i\\n<Esc>'
		local go_printf_lhs = require('KoalaVim.flavor').pick({ koala = '<leader>vp', lazyvim = '<leader>cp' })

		vim.api.nvim_create_autocmd('FileType', {
			pattern = 'go',
			callback = function(events)
				-- TODO: improve GoIfErr
				-- map_buffer(events.buf, 'n', '<leader>e', '<cmd>GoIfErr<cr>', 'Golang: create if err')
				-- stylua: ignore
				kmap_buffer(events.buf, 'n', '<leader>e', 'oif err != nil {<CR>return<CR>}<Esc>', 'Golang: create if err')
				-- `<leader>fl` is buffer lines, `<leader>vl`/`<leader>cl` is LSP info: the key sits in the flavor's code group
				-- stylua: ignore
				map_buffer(events.buf, 'n', go_printf_lhs, '<cmd>s/Println/Printf/<cr>$F"' .. add_new_line, 'Golang: change println to printf')
			end,
		})
	end,
})

return M
