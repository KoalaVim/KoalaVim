local M = {}

-- Formatting goes through the rust-analyzer LSP fallback (no rustfmt in conform)

local map = require('KoalaVim.utils.map')
local remap = require('KoalaVim.keymaps.remap')

-- rustaceanvim, its rust-analyzer settings and codelldb come from LazyVim's rust extra
table.insert(M, {
	'mrcjkb/rustaceanvim',
	opts = function(_, opts)
		-- The extra's buffer-local keys (`<leader>cR`, `<leader>dr`) are rewritten per the flavor
		local extra_on_attach = opts.server.on_attach and remap.on_attach(opts.server.on_attach, 2)

		opts.server.on_attach = function(client, bufnr)
			if extra_on_attach then
				extra_on_attach(client, bufnr)
			end

			map.kmap_buffer(bufnr, 'n', '<F4>', function()
				vim.cmd.RustLsp('codeAction')
			end, 'Code action (rust)')

			-- override hover
			map.kmap_buffer(bufnr, 'n', 'K', function()
				vim.cmd.RustLsp({ 'hover', 'actions' })
			end, 'Trigger hover (rust actions)')

			map.kmap_buffer(bufnr, 'n', 'J', function()
				vim.cmd.RustLsp('joinLines')
			end, 'Rust Join Lines')

			map.kmap_buffer(bufnr, 'n', '<leader>rr', function()
				vim.cmd.RustLsp('runnables')
			end, 'Rust Runnables')

			map.kmap_buffer(bufnr, 'n', '<leader>rt', function()
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
