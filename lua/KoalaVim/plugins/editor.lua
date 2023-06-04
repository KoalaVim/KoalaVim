local M = {}
-- Misc editor plugins
local api = vim.api


table.insert(M, {
	'ofirgall/possession.nvim', -- fork
	dependencies = {
		'nvim-lua/plenary.nvim',
	},
	opts = {
		-- Auto-session with possession.nvim
		autosave = {
			current = true,
			tmp = true,
			tmp_name = function()
				return require('KoalaVim.utils.path').escaped_session_name_from_cwd()
			end,
		},
		commands = {
			save = 'SessionSave',
			load = 'SessionLoad',
			rename = 'SessionRename',
			close = 'SessionClose',
			delete = 'SessionDelete',
			show = 'SessionShow',
			list = nil,
			migrate = nil,
		},
	},
	config = function(_, opts)
		require('possession').setup(opts)
		require('telescope').load_extension('possession')

		local fzy_sorter = require('telescope.sorters').get_fzy_sorter()
		local path_utils = require('KoalaVim.utils.path')

		local current_cwd_session_pattern = '^' .. vim.fn.getcwd()
		local session_sorter = require('telescope.sorters').Sorter:new {
			scoring_function = function(a, prompt, line)
				local fzy_score = fzy_sorter.scoring_function(a, prompt, line)
				if fzy_score < 0 then
					return fzy_score
				end

				if line:match(current_cwd_session_pattern) then
					return 0
				end
				return fzy_score
			end,

			discard = true,
			highlighter = fzy_sorter.highlighter,
		}

		local home_dir_regex = '^' .. vim.loop.os_homedir()
		local get_session_finder = function()
			local sessions = require('possession.query').as_list()
			return require('telescope.finders').new_table {
				results = sessions,
				entry_maker = function(entry)
					local unescaped_name = path_utils.unescape_dir(entry.name)
					return {
						value = entry,
						display = unescaped_name:gsub(home_dir_regex, '~'),
						ordinal = unescaped_name,
					}
				end,
			}
		end

		vim.api.nvim_create_user_command('SessionList', function()
			require('telescope').extensions.possession.list({
				prompt_title = 'Choose Session (sorted by cwd and frequency)',
				previewer = false,
				layout_config = {
					height = 0.30,
					width = 0.40,
				},
				sorter = session_sorter,
				finder = get_session_finder(),
				layout_strategy = 'center',
				sorting_strategy = 'ascending', -- From top
			})
		end, {})
	end,
})

table.insert(M, {
	'ofirgall/AutoSave.nvim', -- fork
	event = 'VeryLazy',
	opts = {
		clean_command_line_interval = 1000,
		on_off_commands = true,
		execution_message = '',
	},
	config = function(_, opts)
		local autosave = require('autosave')
		autosave.setup(opts)

		autosave.hook_before_actual_saving = function()
			-- Ignore RaafatTurki/hex.nvim
			if vim.b.hex then
				vim.g.auto_save_abort = true
				return
			end

			mode = vim.api.nvim_get_mode()
			-- Don't save while we in insert/select mode (triggered with autopair and such)
			if mode.mode ~= 'n' then
				vim.g.auto_save_abort = true
				return
			end
		end
	end,
})

table.insert(M, {
	'gennaro-tedesco/nvim-peekup',
	keys = { '""' },
	config = function()
		local peekup_config = require('nvim-peekup.config')
		peekup_config.on_keystroke['delay'] = ''
		peekup_config.on_keystroke['autoclose'] = true
		peekup_config.on_keystroke['paste_reg'] = '"'
	end,
})

table.insert(M, {
	'ofirgall/guess-indent.nvim', -- fork
	priority = 200, -- Load before auto-session
	opts = {
		post_guess_hook = function(is_tabs)
			vim.b.Koala_tabs = is_tabs
			if is_tabs then
				vim.opt_local.listchars:append('lead:⋅')
			else
				vim.opt_local.listchars:append('lead: ')
			end
		end,
	},
	config = function(_, opts)
		require('guess-indent').setup(opts)
	end,
})

local floating_code_ns = api.nvim_create_namespace('Floating Window for Code')
api.nvim_set_hl(floating_code_ns, 'NormalFloat', { link = 'Normal' })

table.insert(M, {
	'nyngwang/NeoZoom.lua',
	opts = {
		winopts = {
			offset = {
				top = 0.1,
				left = 0.1,
				width = 0.8,
				height = 0.8,
			},
		},
		callbacks = {
			function()
				api.nvim_set_hl_ns(floating_code_ns)
			end,
		},
	},
	config = function(_, opts)
		require('neo-zoom').setup(opts)
	end,
	keys = {
		{
			'<leader>z',
			function() vim.cmd('NeoZoomToggle') end,
			mode = { 'n', 'v' },
			desc = 'Zoom split',
			nowait = true,
		},
	},
})

table.insert(M, {
	'folke/todo-comments.nvim',
	event = { 'BufReadPost', 'BufNewFile' },
	opts = {
		signs = false,
		highlight = {
			before = '',
			keyword = 'fg',
			after = '',
		},
		colors = {
			error = { 'DiagnosticError', 'ErrorMsg', '#DC2626' },
			warning = { '@text.danger', 'DiagnosticWarning', 'WarningMsg', '#FBBF24' },
			info = { '@text.warning', 'DiagnosticInfo', '#2563EB' },
			hint = { '@text.note', 'DiagnosticHint', '#10B981' },
			default = { '@text.note', '#7C3AED' },
		},
	},
	config = function(_, opts)
		require('todo-comments').setup(opts)
	end,
	keys = {
		{ ']t', function() require('todo-comments').jump_next() end, desc = 'Next todo comment' },
		{ '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous todo comment' },
	},
})

table.insert(M, {
	'Vigemus/iron.nvim',
	cmd = { 'IPython', 'Lua' },
	opts = {
		config = {
			should_map_plug = false,
			scratch_repl = true,
			close_window_on_exit = true,
			repl_definition = {
				sh = {
					command = { 'zsh' },
				},
				python = {
					command = { 'ipython3' },
				},
			},
			repl_open_cmd = 'belowright 15 split',
		},
		highlight = {
			italic = false,
			bold = false,
		},
	},
	config = function(_, opts)
		require('iron.core').setup(opts)

		api.nvim_create_user_command('IPython', function()
			require('iron.core').repl_for('python')
			require('iron.core').focus_on('python')
			api.nvim_feedkeys('i', 'n', false)
		end, {})

		api.nvim_create_user_command('Lua', function()
			require('iron.core').repl_for('lua')
			require('iron.core').focus_on('lua')
			api.nvim_feedkeys('i', 'n', false)
		end, {})
	end,
})

table.insert(M, {
	'norcalli/nvim-colorizer.lua',
	event = { 'BufReadPost', 'BufNewFile' },
	opts = {
		'*',
	},
	config = function(_, opts)
		require('colorizer').setup(opts)
	end,
})

table.insert(M, {
	'ziontee113/color-picker.nvim',
	keys = {
		{ '<leader>rgb', '<cmd>PickColor<CR>', desc = 'Pick color' },
	},
	opts = {
	},
	config = function(_, opts)
		require('color-picker').setup(opts)
	end,
})

table.insert(M, {
	'tiagovla/scope.nvim',
	opts = {
	},
	config = function(_, opts)
		require('scope').setup(opts)
	end,
})

local femaco_margin = {
	width = 10,
	height = 6,
	top = 2,
}
table.insert(M, {
	'AckslD/nvim-FeMaco.lua',
	cmd = 'FeMaco',
	keys = {
		{ '<leader>e', function() require('femaco.edit').edit_code_block() end, 'Edit markdown codeblocks' },
	},
	opts = {
		post_open_float = function(winnr)
			api.nvim_win_set_hl_ns(winnr, floating_code_ns)
		end,
		float_opts = function(code_block)
			_ = code_block
			return {
				relative = 'win',
				width = vim.api.nvim_win_get_width(0) - femaco_margin.width,
				height = vim.api.nvim_win_get_height(0) - femaco_margin.height,
				col = femaco_margin.width / 2,
				row = femaco_margin.height / 2 - femaco_margin.top,
				border = 'rounded',
				zindex = 1,
			}
		end,
		ensure_newline = function(_)
			return true
		end,
	},
	config = function(_, opts)
		require('femaco').setup(opts)
	end,
})

table.insert(M, {
	'ofirgall/open.nvim',
	keys = {
		{ '<leader>gx', function() require('open').open_cword() end, desc = 'Open current word' },
	},
	opts = {
	},
	config = function(_, opts)
		require('open').setup(opts)
	end,
	dependencies = {
		{
			'ofirgall/open-jira.nvim',
			config = function(_, opts)
				-- Verify open-jira options
				if not opts.url then
					local koala_opts = require('KoalaVim').opts.plugins.open_jira
					if not require('KoalaVim.opts').verify(koala_opts) then
						return
					end
					opts.url = koala_opts.jira_url
				end

				require('open-jira').setup(opts)
			end,
		},
	},
})

table.insert(M, {
	'zakharykaplan/nvim-retrail',
	event = { 'BufReadPost', 'BufNewFile' },
	cmd = 'TrimWhiteSpace',
	opts = {
		hlgroup = 'NvimInternalError',
		filetype = {
			exclude = {
				'diff',
				'git',
				'gitcommit',
				'unite',
				'qf',
				'help',
				'markdown',
				'fugitive',
				'toggleterm',
				'log',
				'noice',
				'nui',
				'notify',
				'floggraph',
				'chatgpt',
			},
		},
		trim = {
			auto = false,
			whitespace = true, -- Trailing whitespace as highlighted.
			blanklines = true, -- Final blank (i.e. whitespace only) lines.
		},
	},
	config = function(_, opts)
		local retrail = require('retrail')
		retrail.setup(opts)
		api.nvim_create_user_command('TrimWhiteSpace', function() retrail:trim() end, {})
	end,
})

table.insert(M, {
	-- TODO: VimAnavim change to mainline
	'ofirgall/Navigator.nvim', -- To support awesomewm-vim-tmux-navigator
	opts = {
		disable_on_zoom = false,
	},
	config = function(_, opts)
		require('Navigator').setup(opts)
	end,
	keys = {
		{ '<C-h>', '<cmd>NavigatorLeft<cr>', mode = { 'n', 'x', 't' }, desc = 'Navigate left' },
		{ '<C-j>', '<cmd>NavigatorDown<cr>', mode = { 'n', 'x', 't' }, desc = 'Navigate down' },
		{ '<C-k>', '<cmd>NavigatorUp<cr>', mode = { 'n', 'x', 't' }, desc = 'Navigate up' },
		{ '<C-l>', '<cmd>NavigatorRight<cr>', mode = { 'n', 'x', 't' }, desc = 'Navigate right' },
	},
})

table.insert(M, {
	'trmckay/based.nvim',
	opts = {
		highlight = 'Title',
	},
	config = function(_, opts)
		require('based').setup(opts)
	end,
	keys = {
		{ '<leader>H', function() require('based').convert() end, mode = { 'n', 'v' }, desc = 'Convert hex <=> decimal' },
	},
})

table.insert(M, {
	'riddlew/swap-split.nvim',
	cmd = 'SwapSplit',
	opts = {
		ignore_filetypes = {
			'NvimTree',
		},
	},
	config = function(_, opts)
		require('swap-split').setup(opts)
	end,
})

table.insert(M, {
	'RaafatTurki/hex.nvim',
	cmd = { 'HexDump', 'HexAssemble', 'HexToggle' },
	opts = {
	},
	config = function(_, opts)
		require('hex').setup(opts)
	end,
})

table.insert(M, {
	'micarmst/vim-spellsync',
	event = 'VeryLazy',
	init = function()
		vim.g.spellsync_enable_git_union_merge = 0
		vim.g.spellsync_enable_git_ignore = 0
	end,
})

table.insert(M, {
	'ThePrimeagen/harpoon',
	dependencies = {
		'nvim-lua/plenary.nvim',
	},
	keys = {
		{ '<leader>m', function() require('harpoon.mark').add_file() end, desc = 'Add file to harpoon' },
		{ '<leader>A', function() require('telescope').extensions.harpoon.marks() end, desc = 'Jump to harpoon file' },
		{ '<leader>a', function() require('harpoon.ui').toggle_quick_menu() end, desc = 'Jump to harpoon file' },

	},
	config = function()
		require('telescope').load_extension('harpoon')
	end,
})

table.insert(M, {
	'famiu/bufdelete.nvim',
	lazy = true,
})

table.insert(M, {
	'lambdalisue/suda.vim',
	cmd = { 'SudaRead', 'SudaWrite' },
})

table.insert(M, {
	'mizlan/iswap.nvim',
	cmd = 'ISwap',
})

table.insert(M, {
	'rbong/vim-buffest',
	cmd = {
		'Regsplit',
		'Regvsplit',
		'Regtabedit',
		'Regedit',
		'Regpedit',
		'Qflistsplit',
		'Qflistvsplit',
		'Qflisttabedit',
		'Qflistedit',
		'Loclistsplit',
		'Loclistvsplit',
		'Loclisttabedit',
		'Loclistedit',
	},
})

table.insert(M, {
	'ofirgall/vim-log-highlighting',
	ft = 'log',
})

table.insert(M, {
	'chrisgrieser/nvim-genghis',
	cmd = {
		'NewFromSelection',
		'Duplicate',
		'Rename',
		'Trash',
		'Move',
		'CopyFilename',
		'CopyFilepath',
		'Chmodx',
		'New',
	},
})

return M
