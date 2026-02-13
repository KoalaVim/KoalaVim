local M = {}
local api = vim.api

local function node_relative_path()
	local node = require('nvim-tree.api').tree.get_node_under_cursor()

	if node.fs_stat.type == 'directory' then
		return vim.fn.fnamemodify(node.absolute_path, ':.')
	end

	return vim.fn.fnamemodify(node.absolute_path, ':.:h')
end

local function search_in_path()
	local opts = {}
	opts.default_text = '-F "'
	opts.cwd = node_relative_path()
	require('nvim-tree.api').tree.close() -- Close tree before jumping to file
	require('telescope').extensions.live_grep_args.live_grep_args(opts)
end

local function find_in_path()
	local rel_path = node_relative_path()
	require('nvim-tree.api').tree.close() -- Close tree before jumping to file
	vim.api.nvim_exec2('Telescope find_files cwd=' .. rel_path, {}) -- TODO: to lua
end

local function find_and_replace_in_path()
	local rel_path = node_relative_path() .. '/**'

	require('nvim-tree.api').tree.close() -- Close tree before jumping to file
	require('spectre').open({ path = rel_path })
end

local function git_hist_path()
	vim.fn.execute('DiffviewFileHistory ' .. node_relative_path())
end

-- Color scheme
table.insert(M, {
	'ofirgall/ofirkai.nvim',
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
			-- FIXME: show scopes of dicts like this scope
			-- include = {}
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
	keys = {
		{
			'<M-m>',
			function()
				require('nvim-tree.api').tree.toggle()
			end,
			desc = 'Toggle file tree',
		},
		{
			'<M-M>',
			function()
				require('nvim-tree.api').tree.open({ find_file = true })
			end,
			desc = 'Locate file',
		},
	},
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
table.insert(M, {
	'nvim-lualine/lualine.nvim',
	event = 'VeryLazy',
	config = function(_, opts)
		if opts.options == nil then
			opts.options = {
				theme = require('ofirkai.statuslines.lualine').theme,
			}
		end
		require('KoalaVim.utils.ui').setup_lualine(false, opts)

		-- Refresh lualine for recording macros
		api.nvim_create_autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
			callback = require('lualine').refresh,
		})
	end,
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
table.insert(M, {
	'akinsho/bufferline.nvim',
	event = 'VeryLazy',
	opts = {
		options = {
			separator_style = 'slant',
			offsets = {
				{ filetype = 'NvimTree', text = 'File Explorer', text_align = 'center', highlight = 'NvimTreeNormal' },
			},
			show_buffer_icons = true,
			themable = true,
			numbers = 'ordinal',
			max_name_length = 40,
		},
	},
	config = function(_, opts)
		-- TODO: merge highlights with user opts
		opts.highlights = require('ofirkai.tablines.bufferline').highlights

		local bufferline = require('bufferline')
		opts.options.style_preset = {
			bufferline.style_preset.no_italic,
		}
		bufferline.setup(opts)
	end,
})

-- Better `vim.notify()`
table.insert(M, {
	'rcarriga/nvim-notify',
	config = function()
		require('notify').setup({
			background_colour = require('ofirkai.design').scheme.ui_bg,
			fps = 60,
			stages = 'slide',
			timeout = 1000,
			max_width = 50,
			max_height = 20,
		})
	end,
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
	config = function()
		require('noice').setup({
			popupmenu = {
				enabled = false,
			},
			lsp = {
				signature = {
					enabled = true,
				},
				override = {
					-- Override `vim.lsp.buf.hover` and `nvim-cmp` doc formatter with `noice` doc formatter.
					['vim.lsp.util.convert_input_to_markdown_lines'] = true,
					['vim.lsp.util.stylize_markdown'] = true,
					['cmp.entry.get_documentation'] = true,
				},
				progress = {
					-- Using fidget.nvim instead
					enabled = false,
				},
			},
			routes = require('KoalaVim.misc.noice_routes'),
			presets = {
				lsp_doc_border = true, -- add a border to hover docs and signature help
			},
		})
	end,
	keys = {
		{
			'<c-u>',
			function()
				if not require('noice.lsp').scroll(-4) then
					return '<c-u>zz'
				end
			end,
			'Scroll up in hover',
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
			'Scroll down in hover',
			silent = true,
			expr = true,
		},
		{
			'<c-l>',
			function()
				require('KoalaVim.utils.noice').show_signature()
			end,
			'Show function signature',
			mode = 'i',
		},
		{
			'<leader>N',
			function()
				-- Open noice
				require('noice.commands').cmd('')
				vim.cmd('NeoZoomToggle')
			end,
			'Open Noice',
		},
	},
})

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

-- Highlight current window seperator
table.insert(M, {
	'nvim-zh/colorful-winsep.nvim',
	config = function()
		local scheme = require('ofirkai.design').scheme
		require('colorful-winsep').setup({
			highlight = {
				bg = scheme.background,
				fg = scheme.vert_split_fg_active,
			},
		})
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

table.insert(M, {
	'folke/which-key.nvim',
	event = 'VeryLazy',
	config = function(_, opts)
		local wk = require('which-key')
		wk.setup(opts)

		-- TODO: <leader>fm as operator
		local keymaps = {
			mode = { 'n' },
			['<leader>f'] = { name = '+search' },
			['<leader>g'] = { name = '+git' },
			['<leader>h'] = { name = '+git hunks' },
			['<leader>q'] = { name = '+quit' },
			['g'] = { name = '+goto' },
			[']'] = { name = '+next' },
			['['] = { name = '+prev' },
			['s'] = { name = '+surround/split args' },
		}

		-- Hack to show surround and split args
		local map = require('KoalaVim.utils.map').map
		-- stylua: ignore
		map('n', 's', function() wk.show_command('s') end, '', {})
		map('', '<leader><leader>', '<cmd>WhichKey<cr>', '', {})

		wk.register(keymaps)
	end,
})

function CLOSE_KOALA_DASHBOARD(clear_messages, close_buffer)
	KOALA_DASHBOARD_CLOSED = true
	if clear_messages then
		vim.api.nvim_exec_autocmds('User', { pattern = 'AlphaClosed' })
	end
end

table.insert(M, {
	'ofirgall/alpha-nvim', -- fork
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
			dashboard.button('a', '🤖 AI Sidekick', function()
				KoalaDisableAutoSession()
				CLOSE_KOALA_DASHBOARD(true)

				require('sidekick.cli').show()
			end),
			dashboard.button('m', '  File Tree', function()
				CLOSE_KOALA_DASHBOARD(true)
				require('nvim-tree.api').tree.open()
			end),
			dashboard.button('ff', '  Find File', function()
				CLOSE_KOALA_DASHBOARD()

				KoalaDisableAutoSession()
				find_files()
			end),
			dashboard.button('fw', '  Find Text (words)', function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableAutoSession()
				require('telescope.builtin').live_grep()
			end),
			dashboard.button('r', '  Recent files', function()
				CLOSE_KOALA_DASHBOARD()
				KoalaDisableAutoSession()
				require('telescope.builtin').oldfiles()
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

return M
