local M = {}

local usercmd = require('KoalaVim.utils.cmd')

local api = vim.api

-- Collection of quickstart LSP server configurations for Neovim's LSP client
-- Servers are configured through `opts.servers` (LazyVim's registry), see `lsp/servers/*.lua`
table.insert(M, {
	'neovim/nvim-lspconfig',
	init = function()
		-- Attach navic to every client that provides document symbols
		LazyVim.on_very_lazy(function()
			Snacks.util.lsp.on({ method = 'textDocument/documentSymbol' }, function(buffer, client)
				require('nvim-navic').attach(client, buffer)
			end)
		end)
	end,
	opts = {
		-- Hints are rendered at the end of the line by inlay-hints.nvim
		inlay_hints = { enabled = false },
		servers = {
			['*'] = {
				-- Merged into nvim-cmp's capabilities (registered by LazyVim's nvim-cmp extra)
				capabilities = {
					textDocument = {
						completion = { completionItem = { labelDetailsSupport = false } },
					},
				},
				on_init = function(client)
					-- Disable semantic tokens (breaks highlighting)
					client.server_capabilities.semanticTokensProvider = nil
				end,
			},
		},
	},
	keys = {
		{
			'gD',
			vim.lsp.buf.declaration,
			desc = 'Go to Declaration',
		},
		{ 'K', vim.lsp.buf.hover, desc = 'Trigger hover' },
		{ '<RightMouse>', '<LeftMouse><cmd>sleep 100m<cr><cmd>lua vim.lsp.buf.hover()<cr>', desc = 'Trigger hover' },
	},
})

-- Package manager for LSP servers, DAP adapters, linters and formatters
table.insert(M, {
	'mason-org/mason.nvim',
	cmd = { 'MasonInstall' },
	init = function()
		-- Aliases for mason
		-- stylua: ignore start
		usercmd.create('LspServers', 'LSP: show installable servers', function() api.nvim_command('Mason') end, {})
		usercmd.create('Linters', 'LSP: show installable linters', function() api.nvim_command('Mason') end, {})
		usercmd.create('Formatters', 'LSP: show installable formatters', function() api.nvim_command('Mason') end, {})
		-- stylua: ignore end
	end,
	opts = function(_, opts)
		-- Strip asdf shims from PATH so Mason installs don't fail with
		-- "No version is set for command ..." when staging dirs lack .tool-versions
		local asdf_shims = (vim.env.ASDF_DATA_DIR or (vim.env.HOME .. '/.asdf')) .. '/shims'
		local path_parts = vim.split(vim.env.PATH, ':', { plain = true })
		local filtered = vim.tbl_filter(function(p)
			return p ~= asdf_shims
		end, path_parts)
		if #filtered < #path_parts then
			vim.env.PATH = table.concat(filtered, ':')
		end

		opts.npm = { install_args = { '--registry', 'https://registry.npmjs.org/' } }
	end,
})

-- Formatting (conform, <leader>F) is in format.lua, <F2>/<F4>/<leader>L/<leader>l are in diagnostics.lua

-- Render LSP inlay hints as virtual text (parameter names, types)
table.insert(M, {
	'KoalaVim/inlay-hints.nvim', -- fork
	keys = {
		{
			'<leader>T',
			function()
				require('inlay-hints').toggle()
			end,
			desc = 'Toggle inlay-hints',
		},
	},
	config = function()
		local function trim_hint(hint)
			return string.gsub(hint, ':', '')
		end

		require('inlay-hints').setup({
			renderer = 'inlay-hints/render/eol',

			hints = {
				parameter = {
					show = true,
					highlight = 'InlayHints',
				},
				type = {
					show = true,
					highlight = 'InlayHints',
				},
			},

			eol = {
				parameter = {
					separator = ', ',
					format = function(hint)
						return string.format('  (%s)', trim_hint(hint))
					end,
				},
				type = {
					separator = ', ',
					format = function(hint)
						return string.format('  %s', trim_hint(hint))
					end,
				},
			},
		})
	end,
})

-- Highlight other occurrences of the word/symbol under the cursor
-- LazyVim's `editor.illuminate` extra provides the plugin config (opts are merged)
table.insert(M, {
	'RRethy/vim-illuminate',
	opts = {
		modes_denylist = { 'i' },
		filetypes_denylist = {
			'fugitive',
			'NeogitStatus',
			'codediff-explorer',
			'codediff-history',
			'NvimTree',
		},
	},
	keys = {
		{
			'<C-n>',
			function()
				require('illuminate').goto_next_reference({ wrap = true })
				REFRESH_LSP_COUNT()
			end,
			desc = 'jump to Next occurrence of var on cursor',
		},
		{
			'<C-p>',
			function()
				require('illuminate').goto_prev_reference({ reverse = true, wrap = true })
				REFRESH_LSP_COUNT()
			end,
			desc = 'jump to Previous occurrence of var on cursor',
		},
	},
})

-- Show LSP diagnostics as a floating widget next to the cursor/corner
table.insert(M, {
	'KoalaVim/diagflow.nvim', -- fork
	event = 'LspAttach',
	init = function()
		require('KoalaVim.utils.lsp').init_diagnostics_mode()
	end,
	opts = {
		scope = 'line',
		placement = 'inline',
		inline_padding_left = 4,
		show_sign = true,

		severity_colors = {
			error = 'CursorDiagnosticFloatingError',
			warn = 'CursorDiagnosticFloatingWarn',
			info = 'CursorDiagnosticFloatingInfo',
			hint = 'CursorDiagnosticFloatingHint',
		},
	},
	config = function(_, opts)
		require('diagflow').setup(opts)
		-- diagflow uses vim.fn.sign_getdefined to get diagnostic icons
		require('KoalaVim.utils.lsp').setup_diagnostic_signs()
		vim.api.nvim_create_autocmd('InsertEnter', {
			callback = require('KoalaVim.utils.lsp').disable_diagflow,
		})

		vim.api.nvim_create_autocmd('InsertLeave', {
			callback = require('KoalaVim.utils.lsp').enable_diagflow,
		})
	end,
})

-- Interactive tree navigator for LSP document symbols
table.insert(M, {
	'SmiteshP/nvim-navbuddy',
	cmd = 'Navbuddy',
	dependencies = {
		'SmiteshP/nvim-navic',
		'MunifTanjim/nui.nvim',
	},
	config = function()
		require('nvim-navbuddy').setup({
			window = {
				size = '80%',
				left = {
					size = '20%',
				},
				mid = {
					size = '20%',
				},
			},
			lsp = {
				auto_attach = true,
			},
		})

		require('KoalaVim.utils.lsp').late_attach(function(client, bufnr)
			require('nvim-navbuddy').attach(client, bufnr)
		end)

		-- For some reason the usercmd doesn't get called after setup perhaps its mapped to the buffer
		vim.api.nvim_create_user_command('Navbuddy', function()
			require('nvim-navbuddy').open()
		end, {})
	end,
	keys = {
		{
			'<M-n>',
			function()
				require('nvim-navbuddy').open()
			end,
			desc = 'Open Navbuddy',
		},
	},
})

-- Count of LSP definitions and references for the symbol under cursor
table.insert(M, {
	'ofirgall/nvim-dr-lsp', -- fork
	lazy = true,
})

return M
