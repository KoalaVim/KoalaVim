local M = {}
local api = vim.api
local flavor = require('KoalaVim.flavor')
local kkeys = require('KoalaVim.utils.map').kkeys

local function node_relative_path()
	local node = require('nvim-tree.api').tree.get_node_under_cursor()

	if node.fs_stat.type == 'directory' then
		return vim.fn.fnamemodify(node.absolute_path, ':.')
	end

	return vim.fn.fnamemodify(node.absolute_path, ':.:h')
end

local function search_in_path()
	local cwd = node_relative_path()
	require('nvim-tree.api').tree.close()
	require('fff').live_grep({ cwd = cwd })
end

local function find_in_path()
	local rel_path = node_relative_path()
	require('nvim-tree.api').tree.close()
	require('fff').find_files_in_dir(rel_path)
end

local function find_and_replace_in_path()
	local rel_path = node_relative_path() .. '/**'

	require('nvim-tree.api').tree.close() -- Close tree before jumping to file
	require('spectre').open({ path = rel_path })
end

local function git_hist_path()
	vim.fn.execute('CodeDiff history ' .. node_relative_path())
end

-- Color scheme
table.insert(M, {
	'ofirgall/ofirkai.nvim',
	branch = 'feat/lazyvim', -- FIXME: remove after merging to master (colorscheme fix + LazyVim plugin highlights)
	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function(_, opts)
		require('ofirkai').setup(opts)
	end,
	opts = {
		theme = 'dark_blue',
	},
})

-- Indent guides
table.insert(M, {
	'lukas-reineke/indent-blankline.nvim',
	main = 'ibl',
	event = { 'BufReadPost', 'BufNewFile' },
	---@module "ibl"
	---@type ibl.config
	opts = {
		indent = {
			char = '│',
		},
		scope = {
			show_start = false,
			show_end = false,
			highlight = 'IndentContext',
		},
		whitespace = {
			remove_blankline_trail = false,
		},
	},
	config = function(_, opts)
		require('ibl').setup(opts)
	end,
})

-- Add ui for default vim.ui.input
table.insert(M, {
	'stevearc/dressing.nvim',
	lazy = true,
	init = function()
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.select = function(...)
			require('lazy').load({ plugins = { 'dressing.nvim' } })
			return vim.ui.select(...)
		end
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.input = function(...)
			require('lazy').load({ plugins = { 'dressing.nvim' } })
			return vim.ui.input(...)
		end
	end,
	config = function()
		require('dressing').setup({
			input = {
				insert_only = false,
				start_in_insert = false,
				max_width = { 140, 0.9 },
				min_width = { 60, 0.2 },
				mappings = {
					n = {
						['q'] = 'Close',
						['<Esc>'] = 'Close',
						['<CR>'] = 'Confirm',
						['<C-p>'] = 'HistoryPrev',
						['<C-n>'] = 'HistoryNext',
					},
					i = {
						['<M-q>'] = 'Close',
						['<C-c>'] = 'Close',
						['<CR>'] = 'Confirm',
						['<Up>'] = 'HistoryPrev',
						['<Down>'] = 'HistoryNext',
						['<C-p>'] = 'HistoryPrev',
						['<C-n>'] = 'HistoryNext',
					},
				},
				win_options = {
					winblend = 0,
					winhighlight = require('ofirkai.plugins.dressing').winhighlight,
				},
			},
		})
	end,
})

-- File explorer
table.insert(M, {
	'nvim-tree/nvim-tree.lua',
	cmd = 'NvimTreeOpen',
	init = function()
		-- Load nvim-tree.lua if neovim opened with args
		-- relevant in case the user opened nvim with direcotry argument
		local opened_with_args = next(vim.fn.argv()) ~= nil
		if opened_with_args then
			require('nvim-tree')
		end
	end,
	keys = kkeys({
		{
			'<M-m>',
			function()
				require('nvim-tree.api').tree.toggle()
			end,
			desc = 'Toggle file tree',
			mode = { 'n', 't', 'v' },
		},
		{
			'<M-M>',
			function()
				require('nvim-tree.api').tree.open({ find_file = true })
			end,
			desc = 'Locate file',
			mode = { 'n', 't', 'v' },
		},
	}),
	deactivate = function()
		vim.cmd([[NvimTreeClose]])
	end,
	config = function()
		local function on_attach(bufnr)
			local tree_api = require('nvim-tree.api')
			tree_api.config.mappings.default_on_attach(bufnr)

			local map_buffer = require('KoalaVim.utils.map').map_buffer

			map_buffer(bufnr, 'n', '<Escape>', tree_api.node.navigate.parent_close, 'Nvimtree: close node')
			map_buffer(bufnr, 'n', 'h', tree_api.node.navigate.parent_close, 'Nvimtree: close node')
			map_buffer(bufnr, 'n', 'l', tree_api.node.open.edit, 'Nvimtree: open node')
			map_buffer(bufnr, 'n', 'fw', search_in_path, 'Nvimtree: find word in current path')
			map_buffer(bufnr, 'n', 'ff', find_in_path, 'Nvimtree: find files in current path')
			map_buffer(bufnr, 'n', 'fn', find_and_replace_in_path, 'Nvimtree: find and replace in current path')
			map_buffer(bufnr, 'n', 'gh', git_hist_path, 'Nvimtree: view git history in current path')
			map_buffer(bufnr, 'n', 'gh', git_hist_path, 'Nvimtree: view git history in current path')
			map_buffer(bufnr, 'n', '<F2>', tree_api.fs.rename, 'Nvimtree: rename file')
			map_buffer(bufnr, 'n', '<M-j>', tree_api.node.navigate.git.next, 'Next git change')
			map_buffer(bufnr, 'n', '<M-k>', tree_api.node.navigate.git.prev, 'Prev git change')
			map_buffer(bufnr, 'n', '<M-a>', function()
				require('KoalaVim.utils.ai.general').send_context('this')
			end, 'Nvimtree: send node to AI')
		end

		require('nvim-tree').setup({
			on_attach = on_attach,
			view = {
				adaptive_size = true,
				relativenumber = true,
				number = false,
				signcolumn = 'no',
			},
			renderer = {
				symlink_destination = false,
				indent_width = 3,
				indent_markers = {
					enable = true,
					inline_arrows = true,
					icons = {
						item = '│',
					},
				},
				icons = {
					git_placement = 'after',
					modified_placement = 'after',
					glyphs = {
						git = {
							unstaged = '',
							staged = '',
							untracked = '',
							deleted = '',
						},
					},
				},
			},
		})

		HELPERS['NvimTree'] = 'g?'
	end,
})

-- statusline
-- koala: KoalaVim's statusline (`utils/ui.lua`), lazyvim: LazyVim's statusline with the ofirkai theme
table.insert(M, {
	'nvim-lualine/lualine.nvim',
	event = 'VeryLazy',
	opts = function(_, opts)
		if flavor.is('lazyvim') then
			opts.options.theme = require('ofirkai.statuslines.lualine').theme
			opts.options.globalstatus = true -- KoalaVim's options reset `laststatus`
		end
	end,
	-- lazyvim: keep LazyVim's config (plain `setup(opts)`)
	config = flavor.is('koala') and function(_, opts)
		require('KoalaVim.utils.ui').setup_lualine(false, opts)

		-- Refresh lualine for recording macros
		api.nvim_create_autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
			callback = require('lualine').refresh,
		})
	end or nil,
})

-- Git blame (for status line)
table.insert(M, {
	'f-person/git-blame.nvim',
	event = 'VeryLazy',
	init = function()
		if vim.fn.has('wsl') == 1 then -- don't use git blame in wsl because of performance
			vim.g.gitblame_enabled = 0
		else
			vim.g.gitblame_display_virtual_text = 0
			vim.g.gitblame_message_template = '<author> • <date>'
			vim.g.gitblame_date_format = '%d/%m/%Y'
		end
	end,
})

-- Shows context in status line (with lsp)
table.insert(M, {
	'SmiteshP/nvim-navic',
	lazy = true,
	init = function()
		vim.g.navic_silence = true
	end,
	opts = function()
		return {
			separator = '  ',
		}
	end,
})

-- bufferline
-- koala: KoalaVim's tabline, lazyvim: LazyVim's bufferline with the ofirkai colors
table.insert(M, {
	'akinsho/bufferline.nvim',
	event = 'VeryLazy',
	opts = function(_, opts)
		-- TODO: merge highlights with user opts
		opts.highlights = require('ofirkai.tablines.bufferline').highlights

		local nvim_tree_offset =
			{ filetype = 'NvimTree', text = 'File Explorer', text_align = 'center', highlight = 'NvimTreeNormal' }
		if flavor.is('koala') then
			-- Replace LazyVim's options
			opts.options = {
				separator_style = 'slant',
				offsets = { nvim_tree_offset },
				show_buffer_icons = true,
				themable = true,
				numbers = 'ordinal',
				max_name_length = 40,
				style_preset = { require('bufferline').style_preset.no_italic },
			}
		else
			opts.options.themable = true
			table.insert(opts.options.offsets, nvim_tree_offset)
		end
	end,
	-- lazyvim: keep LazyVim's config
	config = flavor.is('koala') and function(_, opts)
		require('bufferline').setup(opts)
	end or nil,
})

-- Nice ui for notify, :messages, and better cmdline
table.insert(M, {
	'folke/noice.nvim',
	enabled = function()
		if vim.env['KOALA_NO_NOICE'] then
			return false
		end
		return true
	end,
	event = 'VeryLazy',
	-- Merged into LazyVim's opts (and its config)
	opts = function(_, opts)
		opts.popupmenu = { enabled = false }
		opts.lsp = vim.tbl_deep_extend('force', opts.lsp or {}, {
			signature = { enabled = true },
			progress = {
				-- Using fidget.nvim instead
				enabled = false,
			},
		})
		-- KoalaVim's routes first, noice stops at the first matching route (LazyVim's `written` route would win)
		opts.routes = vim.list_extend(vim.deepcopy(require('KoalaVim.misc.noice_routes')), opts.routes or {})
		opts.presets = vim.tbl_deep_extend('force', opts.presets or {}, {
			lsp_doc_border = true, -- add a border to hover docs and signature help
		})
	end,
	keys = kkeys({
		{
			'<c-u>',
			function()
				if not require('noice.lsp').scroll(-4) then
					return '<c-u>zz'
				end
			end,
			desc = 'Scroll up in hover',
			silent = true,
			expr = true,
		},
		{
			'<c-d>',
			function()
				if not require('noice.lsp').scroll(4) then
					return '<c-d>zz'
				end
			end,
			desc = 'Scroll down in hover',
			silent = true,
			expr = true,
		},
		{
			'<c-l>',
			function()
				require('KoalaVim.utils.noice').show_signature()
			end,
			desc = 'Show function signature',
			mode = 'i',
		},
		{
			'<leader>N',
			function()
				-- Open noice
				require('noice.commands').cmd('')
				vim.cmd('NeoZoomToggle')
			end,
			desc = 'Open Noice',
		},
	}),
})

-- Floating progress indicator for LSP and background tasks
table.insert(M, {
	'j-hui/fidget.nvim',
	event = 'VeryLazy',
	opts = {
		progress = {
			poll_rate = 10,
			ignore_done_already = true,
			display = {
				done_ttl = 1,
				icon_style = 'NoiceLspProgressSpinner',
				done_style = 'Title',
				group_style = 'Title',

				format_message = function(msg)
					local message = msg.message
					if not message then
						if msg.done then
							return ''
						end
						message = 'In progress...'
					end

					if msg.percentage ~= nil then
						message = string.format('%.0f%%', msg.percentage)
					end
					return message
				end,
			},
		},

		notification = {
			view = {
				group_separator = false,
			},
		},

		integration = {
			['nvim-tree'] = {
				enable = false,
			},
		},
	},
	config = function(_, opts)
		require('fidget').setup(opts)
	end,
})

local _left = ''
local _right = ''
local _up = ''
local _down = ''

-- Highlight current window seperator
table.insert(M, {
	'nvim-zh/colorful-winsep.nvim',
	opts = {
		animate = {
			enabled = false,
			-- enabled = 'shift',
			shift = {
				delta_time = 0.08,
				smooth_speed = 1,
				delay = 3,
			},
		},
		indicator_for_2wins = {
			position = 'center',
			symbols = {
				start_left = _right,
				end_left = _right,
				start_down = _up,
				end_down = _up,
				start_up = _down,
				end_up = _down,
				start_right = _left,
				end_right = _left,
			},
		},
	},
	config = function(_, opts)
		require('colorful-winsep').setup(opts)
	end,
})

-- Status column line
table.insert(M, {
	'luukvbaal/statuscol.nvim',
	event = 'VeryLazy',
	opts = {
		setopt = true,
	},
})

-- icons
table.insert(M, {
	'nvim-tree/nvim-web-devicons',
	lazy = true,
})

-- ui components
table.insert(M, {
	'MunifTanjim/nui.nvim',
	lazy = true,
})

-- Fires `User KoalaDashboardClosed` (flavor independent) when the dashboard closes (see alpha/snacks below)
local function fire_dashboard_closed()
	vim.api.nvim_exec_autocmds('User', { pattern = 'KoalaDashboardClosed' })
end

function CLOSE_KOALA_DASHBOARD(clear_messages, close_buffer)
	KOALA_DASHBOARD_CLOSED = true
	if clear_messages then
		fire_dashboard_closed()
	end
end

-- Greeter/dashboard shown on startup with KoalaVim shortcuts
-- koala flavor: alpha, lazyvim flavor: snacks dashboard (below)
table.insert(M, {
	'KoalaVim/alpha-nvim', -- fork
	-- Not `alpha-nvim`, so LazyVim's optional `goolord/alpha-nvim` specs (dashboard buttons) don't merge into it
	name = 'koala-alpha-nvim',
	enabled = function()
		return flavor.is('koala')
	end,
	event = 'VimEnter',
	opts = function()
		local dashboard = require('alpha.themes.dashboard')
		local logo = [[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⢀⣀⣀⡀⠀⠀
⠀⠀⠀⣀⣀⡀⠀⠀⠀⢀⣀⣀⣀⡀⠘⠋⢉⠙⣷⠀⠀⢀⣾⣿⡿⠁⠀⠀
⢀⣴⣿⡿⠋⣉⠁⣠⣾⣿⣿⣿⣿⡿⠿⣦⡈⠀⣿⡇⠀⣼⣿⣿⠃⠀⠀⠀
⠀⣽⣿⣧⠀⠃⢰⣿⣿⠉⠙⣿⠿⢧⣀⣼⣷⠀⡿⠃⣰⣿⣿⡏⠀⠀⠀⠀
⠀⠉⣿⣿⣦⠀⢿⣿⣿⣷⣾⡏⠀⠀⢹⣿⣿⠀⠀⢰⣿⣿⡟⠀⠀⠀⠀⠀
⠀⠀⠀⠉⠛⠁⠈⠿⣿⣿⣿⣷⣄⣠⡼⠟⠁⠀⢠⣿⣿⡿⠁⠀
⠀⠀⠀⠀⠀⠀⢀⣤⣤⣄⣉⣉⣉⣠⡀⠀⠀⢀⡿⠿⢿⠃⠀⠀ _  __           _     __     ___
⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣤⣤⣶⣄⠀⠀⠀| |/ /___   __ _| | __ \ \   / (_)_ __ ___
⠀⠀⠀⢀⣾⣿⣿⣿⣿⠟⠋⣉⣉⠙⠻⣿⣿⣿⣿⠿⠋⠀⠀⠀| ' // _ \ / _` | |/ _` \ \ / /| | '_ ` _ \
⠀⠀⠀⣾⣿⣿⣿⡏⢀⣴⣿⣿⣿⣿⡄⢀⣤⣤⡄⠀⠀⠀⠀⠀| . \ (_) | (_| | | (_| |\ V / | | | | | | |
⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⢀⣤⣤⠀⠀⠀⠀⠀⠀|_|\_\___/ \__,_|_|\__,_| \_/  |_|_| |_| |_|
⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⣠⣿⣿⠿⠁
⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⣯⣠⣾⡿⠋⠀
⠀⠀⠀⠀⠉⠻⠿⣿⣿⣿⣿⣿⠿⠋⣠⡾
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠁
]]

		local kvim_conf = require('KoalaVim.conf')
		dashboard.section.header.val = vim.split(logo, '\n')
		dashboard.section.buttons.val = {
			dashboard.button('ss', '  Load Session', function()
				CLOSE_KOALA_DASHBOARD()

				require('KoalaVim.utils.session').load_cwd_session()
			end),
			dashboard.button('sl', '  Session List', ':SessionList <CR>'),
			dashboard.button('a', '󰚩  AI Sidekick', function()
				KoalaDisableAutoSession()
				CLOSE_KOALA_DASHBOARD(true)

				require('KoalaVim.utils.modes').load('ai')
			end),
			dashboard.button('m', '  File Tree', function()
				CLOSE_KOALA_DASHBOARD(true)
				require('nvim-tree.api').tree.open()
			end),
			dashboard.button('ff', '  Find File', function()
				CLOSE_KOALA_DASHBOARD()

				KoalaDisableAutoSession()
				require('fff').find_files()
			end),
			dashboard.button('fw', '  Find Text (words)', function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableAutoSession()
				require('fff').live_grep()
			end),
			dashboard.button('r', '  Recent files', function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableAutoSession()
				Snacks.picker.recent()
			end),

			dashboard.button('gs', '  Git Tree & Status', function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableSession()

				require('KoalaVim.utils.modes').load('git')
			end),

			dashboard.button('gd', '𝝙  Git Diff', function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableSession()

				require('KoalaVim.utils.modes').load('git_diff')
			end),

			dashboard.button('kc', ' ' .. ' Koala Config', function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableAutoSession(true)
				vim.cmd(':e ' .. kvim_conf.get_user_conf())
			end),

			dashboard.button('krc', ' ' .. ' Koala Repo Config', function()
				CLOSE_KOALA_DASHBOARD()

				local repo_conf = kvim_conf.get_repo_conf()
				if repo_conf == nil then
					vim.notify('Not in a git repository')
					return
				end

				KoalaDisableAutoSession(true)
				local json_file = require('KoalaVim.utils.json_file')
				json_file.create_default(repo_conf, {})
				vim.cmd(':e ' .. repo_conf)
			end),

			dashboard.button('ku', ' ' .. ' Koala Update', function()
				CLOSE_KOALA_DASHBOARD()

				require('KoalaVim.utils.update_checker').update()
			end),

			dashboard.button('kl', ' ' .. ' Koala Change Log', function()
				CLOSE_KOALA_DASHBOARD()

				require('KoalaVim.utils.changelog').check()
			end),

			dashboard.button('q', ' ' .. ' Quit', ':qa<CR>'),
		}
		for _, button in ipairs(dashboard.section.buttons.val) do
			button.opts.hl = 'Constant'
			button.opts.hl_shortcut = 'Function'
		end
		dashboard.section.footer.opts.hl = 'Number'
		dashboard.section.header.opts.hl = 'Title'
		dashboard.section.buttons.opts.hl = 'Number'
		dashboard.opts.layout[1].val = 4
		return dashboard
	end,
	config = function(_, dashboard)
		-- Don't load dashboard on restart
		if vim.env.KOALA_RESTART then
			return
		end

		-- Skip dashboard when loading into koala mode
		if vim.env.KOALA_MODE then
			return
		end

		vim.api.nvim_create_autocmd('User', {
			pattern = 'AlphaClosed',
			callback = fire_dashboard_closed,
		})

		vim.api.nvim_create_autocmd('User', {
			pattern = 'AlphaReady',
			callback = function()
				require('KoalaVim.utils.update_checker').check()
				-- close Lazy and re-open when the dashboard is ready
				if vim.o.filetype == 'lazy' then
					require('lazy').show()
				end
			end,
		})

		require('alpha').setup(dashboard.opts)

		vim.api.nvim_create_autocmd('User', {
			pattern = 'LazyVimStarted',
			callback = function()
				local stats = require('lazy').stats()
				local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
				dashboard.section.footer.val = {
					' Press SPACE twice for keybind help',
					'',
					' Type :ListKeys for keybinds help',
					'',
					' Type :ListCmds for commands help',
				}
				pcall(vim.cmd.AlphaRedraw)
			end,
		})
	end,
})

-- Dashboard for the lazyvim flavor: LazyVim's snacks dashboard with KoalaVim's buttons
table.insert(M, {
	'folke/snacks.nvim',
	opts = function(_, opts)
		opts.dashboard = opts.dashboard or {}
		-- Same as the alpha dashboard, don't show on restart or when loading into koala mode
		opts.dashboard.enabled = flavor.is('lazyvim') and not vim.env.KOALA_RESTART and not vim.env.KOALA_MODE
		if not flavor.is('lazyvim') then
			return
		end

		-- Insert before `Quit`
		local keys = opts.dashboard.preset.keys
		local quit = #keys
		for i, key in ipairs(keys) do
			if key.key == 'q' then
				quit = i
			end
		end
		-- stylua: ignore
		local koala_keys = {
			{ icon = '󰚩 ', key = 'a', desc = 'AI Sidekick', action = function()
				KoalaDisableAutoSession()
				CLOSE_KOALA_DASHBOARD(true)
				require('KoalaVim.utils.modes').load('ai')
			end },
			{ icon = '𝝙 ', key = 'd', desc = 'Git Diff', action = function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableSession()
				require('KoalaVim.utils.modes').load('git_diff')
			end },
			{ icon = ' ', key = 'u', desc = 'Koala Update', action = function()
				CLOSE_KOALA_DASHBOARD()
				require('KoalaVim.utils.update_checker').update()
			end },
			{ icon = ' ', key = 'C', desc = 'Koala Change Log', action = function()
				CLOSE_KOALA_DASHBOARD()
				require('KoalaVim.utils.changelog').check()
			end },
		}
		for i, key in ipairs(koala_keys) do
			table.insert(keys, quit + i - 1, key)
		end
	end,
	init = function()
		if not flavor.is('lazyvim') then
			return
		end

		vim.api.nvim_create_autocmd('User', {
			pattern = 'SnacksDashboardClosed',
			callback = fire_dashboard_closed,
		})
		vim.api.nvim_create_autocmd('User', {
			pattern = 'SnacksDashboardOpened',
			callback = function()
				require('KoalaVim.utils.update_checker').check()
			end,
		})
	end,
})

-- Smooth animated cursor trail rendered inside the terminal
table.insert(M, {
	'sphamba/smear-cursor.nvim',
	event = 'VeryLazy',
	cond = vim.g.neovide == nil,
	opts = {
		-- stylua: ignore start               -- Default  Range
		-- stiffness = 0.8,                      -- 0.6      [0, 1]
		-- trailing_stiffness = 0.6,             -- 0.45     [0, 1]
		-- stiffness_insert_mode = 0.7,          -- 0.5      [0, 1]
		-- trailing_stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
		-- damping = 0.95,                       -- 0.85     [0, 1]
		-- damping_insert_mode = 0.95,           -- 0.9      [0, 1]
		-- distance_stop_animating = 0.5,        -- 0.1      > 0
		-- stylua: ignore end

		-- Fixes issues with blinking chars after animating
		hide_target_hack = true,
		never_draw_over_target = true,

		cursor_color = 'none',
		legacy_computing_symbols_support = true,
		smear_insert_mode = false, -- no effect?
	},
	config = function(_, opts)
		require('smear_cursor').setup(opts)

		vim.api.nvim_create_autocmd('VimEnter', {
			callback = function()
				io.write('\x1b]7776;shader=off\x1b\\')
			end,
		})

		vim.api.nvim_create_autocmd('VimLeave', {
			callback = function()
				io.write('\x1b]7776;shader=on\x1b\\')
			end,
		})
	end,
	specs = {},
})

-- Dim inactive windows and buffers for better focus
table.insert(M, {
	'tadaa/vimade', -- Dims inactive windows
	enabled = false,
	opts = {
		recipe = { 'default', { animate = false } },
		ncmode = 'windows',
		fadelevel = 0.55,
		-- enablefocusfading = true,
		blocklist = {
			default = {
				buf_opts = {
					ft = {
						'git',
						'floggraph',
						'sidekick_terminal',
						-- FIXME: fix tinting fucks up coloring
						'NeogitStatus', -- to avoid coloring issues
					},
				},
			},
		},
	},
})
return M
