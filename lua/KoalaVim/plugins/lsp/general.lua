local M = {}

local usercmd = require('KoalaVim.utils.cmd')

local api = vim.api

-- diagnostics_icons.Error, '', '', '', '', '',
local diagnostics_virt_text_settings = {
	severity = vim.diagnostic.severity.ERROR,
	prefix = '',
}

LSP_ON_INIT = function(client)
	-- Disable semantic tokens (breaks highlighting)
	client.server_capabilities.semanticTokensProvider = nil
end

LSP_ON_ATTACH = function(client, buffer)
	-- Attach navic
	if client.server_capabilities.documentSymbolProvider then
		require('nvim-navic').attach(client, buffer)
	end
end

LSP_ON_ATTACH_NO_HOVER = function(client, buffer)
	LSP_ON_ATTACH(client, buffer)
	client.server_capabilities.hoverProvider = false
end

-- Setup actual servers + generic lsp stuff
table.insert(M, {
	'neovim/nvim-lspconfig',
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'hrsh7th/cmp-nvim-lsp',
		'mason.nvim',
		{
			'folke/neodev.nvim', -- Must be loaded before setting up lua_ls
			config = function()
				require('neodev').setup({
					library = {
						plugins = { 'nvim-treesitter', 'plenary.nvim', 'ofirkai.nvim', 'lazy.nvim' },
					},
				})
			end,
		},
		'williamboman/mason-lspconfig.nvim',
		{
			'mhanberg/output-panel.nvim',
			config = function()
				require('output_panel').setup()
				usercmd.create('LspOutput', 'LSP: show servers output panel', ':OutputPanel', {})
			end,
		},
	},
	config = function(_, _)
		-- Config diagnostics behavior
		vim.diagnostic.config({
			update_in_insert = false, -- disable updates
			-- Start virtual text and lines disabled
			virtual_lines = false,
			virtual_text = diagnostics_virt_text_settings,
			signs = {
				priority = 8,
			},
		})

		-- hrsh7th/cmp-nvim-lsp
		-- TODO: [VimAnavim] config LspCaps
		LSP_CAPS = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
		LSP_CAPS.textDocument.completion.completionItem.labelDetailsSupport = nil -- Overriding with false doesn't work for some reason

		local function setup_server(server)
			local server_opts_merged = vim.tbl_deep_extend('force', {
				capabilities = LSP_CAPS,
				on_attach = LSP_ON_ATTACH,
				on_init = LSP_ON_INIT,
			}, LSP_SERVERS[server] or {})

			if server_opts_merged.lazy then
				return -- Server is lazy initialized
			end
			require('lspconfig')[server].setup(server_opts_merged)
		end

		local function setup_server_filtered(server)
			if LSP_SERVERS[server] then
				return setup_server(server)
			end
		end

		local mason_ensure_installed = {}
		local mlsp = require('mason-lspconfig')
		local mason_available_servers = mlsp.get_available_servers()

		for server, server_opts in pairs(LSP_SERVERS) do
			if server_opts.mason == false or not vim.tbl_contains(mason_available_servers, server) then
				setup_server(server)
			else
				table.insert(mason_ensure_installed, server)
			end
		end

		require('mason-lspconfig').setup({
			ensure_installed = mason_ensure_installed,
		})
		require('mason-lspconfig').setup_handlers({
			setup_server_filtered,
		})

		-- Icons
		for name, icon in pairs(require('KoalaVim.utils.icons').diagnostics) do
			name = name:gsub('^%l', string.upper) -- Captial first letter
			name = 'DiagnosticSign' .. name
			vim.fn.sign_define(name, { text = icon, texthl = name, numhl = '' })
		end
	end,
	keys = {
		{
			'gD',
			vim.lsp.buf.declaration,
			desc = 'Go to Declaration',
		},
		{
			'<leader>F',
			function()
				require('KoalaVim.utils.lsp').format(true)
			end,
			desc = 'Format',
		},
		{ 'K', vim.lsp.buf.hover, desc = 'Trigger hover' },
		{ '<RightMouse>', '<LeftMouse><cmd>sleep 100m<cr><cmd>lua vim.lsp.buf.hover()<cr>', desc = 'Trigger hover' },
	},
})

table.insert(M, {
	'amittamari/mason.nvim', -- fork
	cmd = {
		'Mason',
		'MasonInstall',
		'Linters',
		'LspServers',
		'Formatters',
	},
	opts = {
		-- Linters
		-- TODO: take from NONE_LS_SRCS
		ensure_installed = {
			'stylua',
			'shfmt',
			'mypy',
			-- TODO: take from DAP
			'debugpy',
		},
		npm = {
			install_args = { '--registry', 'https://registry.npmjs.org/' },
		},
	},
	config = function(_, opts)
		require('mason').setup(opts)

		-- Aliases for mason
		-- stylua: ignore start
		usercmd.create('LspServers', 'LSP: show installable servers', function() api.nvim_command('Mason') end, {})
		usercmd.create('Linters', 'LSP: show installable linters', function() api.nvim_command('Mason') end, {})
		usercmd.create('Formatters', 'LSP: show installable formatters', function() api.nvim_command('Mason') end, {})
		-- stylua: ignore end

		local mr = require('mason-registry')
		for _, tool in ipairs(opts.ensure_installed) do
			local p = mr.get_package(tool)
			if not p:is_installed() then
				p:install()
			end
		end
	end,
})

table.insert(M, {
	-- Formatters/linters
	'nvimtools/none-ls.nvim',
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = { 'mason.nvim' },
	opts = {
		-- debug = true, -- Goes to ~/.cache/nvim/null-ls.log
		sources = {},
		-- Setup null-ls builtins sources as traversed table
		builtins_sources = {
			formatting = {},
			code_actions = {},
			diagnostics = {},
		},
	},
	config = function(_, opts)
		local null_ls = require('null-ls')
		local health = require('KoalaVim.health')

		local builtins_sources = {}
		local function traverse_builtin(aggregated, current)
			for key, value in pairs(current) do
				if type(value) == 'table' then
					if aggregated[key] == nil then
						health.warn('[null-ls-builtins] invalid source, ' .. key .. ' not found')
					else
						-- aggregated = aggregated[key]
						traverse_builtin(aggregated[key], value)
					end
				elseif type(value) == 'string' then
					table.insert(builtins_sources, aggregated[value])
				else
					health.warn('[null-ls-builtins] expected string|table found ' .. type(key))
				end
			end
		end

		local builtins_sources_overrides = {}

		-- Process configured sources
		for src, src_opts in pairs(NONE_LS_SRCS) do
			-- Merge sources
			opts.sources = vim.tbl_extend('force', opts.sources, src_opts.sources or {})

			-- Fill traversed builtins_sources
			for k, v in pairs(src_opts.builtins_sources) do
				local src_type = v
				-- Take overrides of builtin_opts
				if type(v) == 'table' then
					src_type = k
					builtins_sources_overrides[src] = v
				end

				table.insert(opts.builtins_sources[src_type], src)
			end
		end

		-- DEBUG(builtins_sources_overrides, 'builtins_sources_overrides')

		traverse_builtin(null_ls.builtins, opts.builtins_sources)
		opts.sources = vim.tbl_extend('keep', opts.sources, builtins_sources)

		for i, src_opts in ipairs(opts.sources) do
			local src = src_opts.name

			if builtins_sources_overrides[src] then
				opts.sources[i] = opts.sources[i].with(builtins_sources_overrides[src])
			end

			if NONE_LS_SRCS[src].with then
				opts.sources[i] = opts.sources[i].with(NONE_LS_SRCS[src].with)
			end
		end

		-- DEBUG(opts, 'null_ls opts')
		if #opts.builtins_sources.formatting > 0 then
			health.error("[null-ls] formatting with null-ls isn't supported, use conform.")
		end

		null_ls.setup(opts)
	end,
})

-- TODO fix me?
local MASON_BIN_PATH = vim.fn.expand('$HOME/.local/share/kvim/upstream/nvim/mason/bin/')

table.insert(M, {
	'stevearc/conform.nvim',
	event = { 'BufWritePre' },
	cmd = { 'ConformInfo' },
	config = function()
		local formatters = {}
		for _, formatter in ipairs(CONFORM_FORMATTERS_BY_FT) do
			if formatters[formatter] == nil then
				table.insert(formatters, { command = MASON_BIN_PATH .. formatter })
			end
		end

		require('conform').setup({
			formatters_by_ft = CONFORM_FORMATTERS_BY_FT,
			formatters = formatters,
		})
	end,
})

-- TODO: if I want code action to be always active I need to add event = 'LspAttach'
table.insert(M, {
	'glepnir/lspsaga.nvim',
	dependencies = {
		'nvim-tree/nvim-web-devicons',
		'nvim-treesitter/nvim-treesitter',
	},
	config = function()
		local scheme = require('ofirkai.design').scheme

		require('lspsaga').setup({
			code_action = {
				keys = {
					quit = '<Escape>',
					exec = '<CR>',
				},
			},
			lightbulb = {
				sign_priority = 10,
				sign = true,
				virtual_text = false,
				enable_in_insert = false,
			},
			rename = {
				quit = '<esc>',
				in_select = false,
			},
			symbol_in_winbar = {
				enable = false,
			},
			ui = {
				code_action = '',
				colors = {
					normal_bg = scheme.ui_bg,
					title_bg = scheme.mid_orange,
				},
				lines = { '└', '├', '│', '─' },
			},
		})
	end,
	keys = {
		{ '<F2>', '<cmd>Lspsaga rename<cr>', desc = 'Rename symbos with F2' },
		{ '<F4>', '<cmd>Lspsaga code_action<cr>', desc = 'Code action with F4' },
		{ '<leader>L', '<cmd>Lspsaga show_line_diagnostics<CR>', desc = 'show Problem' },
	},
})

table.insert(M, {
	'ofirgall/inlay-hints.nvim', -- fork
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

table.insert(M, {
	'ofirgall/format-on-leave.nvim',
	event = 'LspAttach',
	config = function()
		require('format-on-leave').setup({
			format_func = require('KoalaVim.utils.lsp').auto_format,
		})
	end,
})

table.insert(M, {
	'RRethy/vim-illuminate',
	event = 'LspAttach',
	config = function()
		require('illuminate').configure({
			modes_denylist = { 'i' },
		})
	end,
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

-- Disable virtual text and enables lsp lines and vise versa
local function toggle_lsp_diagnostics()
	local new_lines_value = not vim.diagnostic.config().virtual_lines
	local virtual_text = nil

	if new_lines_value == false then
		virtual_text = diagnostics_virt_text_settings
	else
		virtual_text = false
	end

	vim.diagnostic.config({
		virtual_lines = new_lines_value,
		virtual_text = virtual_text,
	})
end

table.insert(M, {
	'ofirgall/lsp_lines.nvim', -- mirror of https://git.sr.ht/~whynothugo/lsp_lines.nvim
	config = function()
		require('lsp_lines').setup()
	end,
	keys = {
		{ '<leader>l', toggle_lsp_diagnostics, desc = 'Toggle lsp diagnostics' },
	},
})

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
			'<C-g>s',
			function()
				require('nvim-navbuddy').open()
			end,
			desc = 'Open Navbuddy',
		},
	},
})

table.insert(M, {
	-- Adds definition and references to statusline
	'ofirgall/nvim-dr-lsp', -- fork
	lazy = true,
})

return M
