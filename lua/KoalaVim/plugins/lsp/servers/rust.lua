local M = {}

-- Formatting goes through the rust-analyzer LSP fallback (no rustfmt in conform)

local map = require('KoalaVim.utils.map')

-- rustaceanvim, its rust-analyzer settings and codelldb come from LazyVim's rust extra
table.insert(M, {
	'mrcjkb/rustaceanvim',
	opts = function(_, opts)
		local extra_on_attach = opts.server.on_attach

		opts.server.on_attach = function(client, bufnr)
			if extra_on_attach then
				extra_on_attach(client, bufnr)
			end

			map.map_buffer(bufnr, 'n', '<F4>', function()
				vim.cmd.RustLsp('codeAction')
			end, 'Rust Code Action')

			-- override hover
			map.map_buffer(bufnr, 'n', 'K', function()
				vim.cmd.RustLsp({ 'hover', 'actions' })
			end, 'Rust Hover')

			map.map_buffer(bufnr, 'n', 'J', function()
				vim.cmd.RustLsp('joinLines')
			end, 'Rust Join Lines')

			map.map_buffer(bufnr, 'n', '<leader>rr', function()
				vim.cmd.RustLsp('runnables')
			end, 'Rust Runnables')

			map.map_buffer(bufnr, 'n', '<leader>rt', function()
				vim.cmd.RustLsp('testables')
			end, 'Rust Testables')
		end
	end,
})

-- The extra doesn't install rust-analyzer
table.insert(M, {
	'mason-org/mason.nvim',
	opts = { ensure_installed = { 'rust-analyzer' } },
})

-- Jump to the next Rust compile error via cargo-limit (run cargo lrun/lcheck)
table.insert(M, {
	'alopatindev/cargo-limit',
	run = 'cargo install cargo-limit nvim-send',
	ft = 'rust',
})

return M
