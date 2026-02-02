local M = {}

-- for some reason format of rust-analyzer + conform + format-on-leave doesn't work.
-- using rustfmt through conform solves the problem.
-- CONFORM_FORMATTERS['rustfmt'] = { 'rust' }

local map = require('KoalaVim.utils.map')

LSP_SERVERS['rust-analyzer'] = {
	dont_setup = true, -- Dont setup but install with mason
	mason = 'rust_analyzer',
}

table.insert(M, {
	'mrcjkb/rustaceanvim',
	ft = 'rust',
	opts = {
		server = {
			on_attach = function(_, bufnr)
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
			end,
			default_settings = {
				-- rust-analyzer language server configuration
				['rust-analyzer'] = {
					cargo = {
						allFeatures = true,
						loadOutDirsFromCheck = true,
						buildScripts = {
							enable = true,
						},
					},
					-- FIXME: add bacon from LazyVim
					-- Add clippy lints for Rust if using rust-analyzer
					checkOnSave = 'rust-analyzer',
					-- Enable diagnostics if using rust-analyzer
					diagnostics = {
						enable = 'rust-analyzer',
					},
					procMacro = {
						enable = true,
					},
					files = {
						exclude = {
							'.direnv',
							'.git',
							'.jj',
							'.github',
							'.gitlab',
							'bin',
							'node_modules',
							'target',
							'venv',
							'.venv',
						},
						-- Avoid Roots Scanned hanging, see https://github.com/rust-lang/rust-analyzer/issues/12613#issuecomment-2096386344
						watcher = 'client',
					},
				},
			},
		},
	},
	config = function(_, opts)
		vim.g.rustaceanvim = vim.tbl_deep_extend('keep', vim.g.rustaceanvim or {}, opts or {})
	end,
})

table.insert(M, {
	-- Jump to rust errors (run `cargo lrun` in terminal)
	'alopatindev/cargo-limit',
	run = 'cargo install cargo-limit nvim-send',
	ft = 'rust',
})

return M
