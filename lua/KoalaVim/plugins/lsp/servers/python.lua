local M = {}

-- pyright and ruff come from LazyVim's python extra (the extra turns off ruff's hover in favor of pyright)
table.insert(M, {
	'neovim/nvim-lspconfig',
	opts = {
		servers = {
			pyright = {
				settings = {
					pyright = {
						disableOrganizeImports = true,
						reportMissingModuleSource = 'none',
						reportMissingImports = 'none',
						reportUndefinedVariable = 'none',
					},
					python = {
						analysis = {
							autoSearchPaths = true,
							diagnosticMode = 'workspace',
							typeCheckingMode = 'off',
							useLibraryCodeForTypes = true,
						},
					},
				},
			},
			ruff = {
				dont_format = true, -- Format through 'ruff' cli. async formatting with this lsp is broken. (deletes code)
			},
		},
	},
})

table.insert(M, {
	'stevearc/conform.nvim',
	opts = {
		formatters_by_ft = {
			python = { 'black', 'ruff_format' },
		},
	},
})

table.insert(M, {
	'mason-org/mason.nvim',
	opts = {
		-- `ruff` is installed by the server. debugpy isn't installed by LazyVim's python extra
		ensure_installed = { 'black', 'mypy', 'debugpy' },
	},
})

-- Type checker. Runs only on save (mypy is slow), unlike LazyVim's linters which run on read/insert leave too
local saved = {}
table.insert(M, {
	'mfussenegger/nvim-lint',
	init = function()
		vim.api.nvim_create_autocmd('BufWritePost', {
			pattern = '*.py',
			group = vim.api.nvim_create_augroup('KoalaVimMypyOnSave', { clear = true }),
			callback = function(args)
				saved[vim.api.nvim_buf_get_name(args.buf)] = true
			end,
		})
	end,
	opts = {
		linters_by_ft = {
			python = { 'mypy' },
		},
		linters = {
			mypy = {
				prepend_args = { '--check-untyped-defs' },
				condition = function(ctx)
					local was_saved = saved[ctx.filename]
					saved[ctx.filename] = nil
					return was_saved
				end,
				parser = function(output, bufnr, cwd)
					local diagnostics = require('lint.linters.mypy').parser(output, bufnr, cwd)
					for _, diagnostic in ipairs(diagnostics) do
						if diagnostic.code == 'import-not-found' or diagnostic.code == 'import-untyped' then
							diagnostic.code = 'Missing library stubs (typeshed) or py.typed file'
							diagnostic.severity = vim.diagnostic.severity['INFO']
						end
					end
					return diagnostics
				end,
			},
		},
	},
})

return M
