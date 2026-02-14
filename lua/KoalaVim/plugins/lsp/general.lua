local M = {}

local usercmd = require('KoalaVim.utils.cmd')

local api = vim.api

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
		'williamboman/mason-lspconfig.nvim',
		{
			'mhanberg/output-panel.nvim',
			enabled = false,
			config = function()
				require('output_panel').setup()
				usercmd.create('LspOutput', 'LSP: show servers output panel', ':OutputPanel', {})
			end,
		},
	},
	config = function(_, _)
		-- hrsh7th/cmp-nvim-lsp
		-- TODO: [VimAnavim] config LspCaps
		LSP_CAPS = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
		LSP_CAPS.textDocument.completion.completionItem.labelDetailsSupport = nil -- Overriding with false doesn't work for some reason

		local function setup_server(server)
			-- FIXME: vim.lsp: re-visit capabilities, on_attach and on_init
			local server_opts_merged = vim.tbl_deep_extend('force', {
				capabilities = LSP_CAPS,
				on_attach = LSP_ON_ATTACH,
				on_init = LSP_ON_INIT,
			}, LSP_SERVERS[server] or {})

			vim.lsp.config[server] = server_opts_merged
			vim.lsp.enable(server)
		end

		local mason_ensure_installed = {}
		local mlsp = require('mason-lspconfig')
		local mason_available_servers = mlsp.get_available_servers()
		-- DEBUG(mason_available_servers, 'mason_available_servers')

		for server, server_opts in pairs(LSP_SERVERS) do
			-- Use mason name instead of server name if .mason set to string
			local mason_server_name = server_opts.mason or server

			if server_opts.mason ~= false and vim.tbl_contains(mason_available_servers, mason_server_name) then
				table.insert(mason_ensure_installed, mason_server_name)
			end

			if server_opts.dont_setup ~= true then
				setup_server(server)
			end
		end
		DEBUG(mason_ensure_installed, 'mason_ensure_installed')

		require('mason-lspconfig').setup({
			ensure_installed = mason_ensure_installed,
			automatic_enable = false,
		})

		-- Init diagnostics mode
		require('KoalaVim.utils.lsp').set_diagnostics_mode(1)
	end,
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

table.insert(M, {
	'mason-org/mason.nvim',
	cmd = {
		'Mason',
		'MasonInstall',
		'Linters',
		'LspServers',
		'Formatters',
	},
	opts = {
		-- Linters
		ensure_installed = {
			-- TODO: take from DAP
			'debugpy',
		},
		npm = {
			install_args = { '--registry', 'https://registry.npmjs.org/' },
		},
	},
	config = function(_, opts)
		-- convert to list to set
		local ensure_installed = {}
		for _, formatter in ipairs(opts.ensure_installed) do
			ensure_installed[formatter] = true
		end

		-- Add to ensure_installed from conform formatters
		for formatter, info in pairs(CONFORM_FORMATTERS) do
			if info.mason == nil then
				ensure_installed[formatter] = true
			else
				if info.mason then
					ensure_installed[info.mason] = true
				end
			end
		end

		for null_ls_src, _ in pairs(NONE_LS_SRCS) do
			ensure_installed[null_ls_src] = true
		end

		-- convert set to list
		opts.ensure_installed = vim.tbl_keys(ensure_installed)
		-- DEBUG(opts.ensure_installed, 'ensure_installed')

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

table.insert(M, {
	'stevearc/conform.nvim',
	module = true, -- loaded as module by format-on-leave
	cmd = { 'ConformInfo' },
	keys = {
		{
			'<leader>F',
			function()
				require('KoalaVim.utils.lsp').format(true)
			end,
			desc = 'Format',
		},
	},
	config = function()
		local formatters_cmds = {}
		local formatters_by_ft = {}
		for formatter, fts in pairs(CONFORM_FORMATTERS) do
			table.insert(formatters_cmds, { command = formatter })

			for _, ft in ipairs(fts) do
				if formatters_by_ft[ft] == nil then
					formatters_by_ft[ft] = { formatter }
				else
					table.insert(formatters_by_ft[ft], formatter)
				end
			end
		end

		require('conform').setup({
			formatters_by_ft = formatters_by_ft,
			formatters = formatters_cmds,
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
	branch = 'conform', -- FIXME: remove this after merging to master
	config = function()
		require('format-on-leave').setup({
			format_func = require('KoalaVim.utils.lsp').auto_format,
			conform = {
				enabled = true,
			},
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

table.insert(M, {
	'ofirgall/lsp_lines.nvim', -- mirror of https://git.sr.ht/~whynothugo/lsp_lines.nvim
	config = function()
		require('lsp_lines').setup()
	end,
	keys = {
		{
			'<leader>l',
			function()
				require('KoalaVim.utils.lsp').cycle_lsp_diagnostics()
			end,
			desc = 'Cycle between lsp diagnostics mode',
		},
	},
})

table.insert(M, {
	'ofirgall/diagflow.nvim', -- fork
	event = 'LspAttach',
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
		vim.api.nvim_create_autocmd('InsertEnter', {
			callback = require('KoalaVim.utils.lsp').disable_diagflow,
		})

		vim.api.nvim_create_autocmd('InsertLeave', {
			callback = require('KoalaVim.utils.lsp').enable_diagflow,
		})
	end,
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
