local M = {}
-- Misc editor plugins
local api = vim.api

local usercmd = require('KoalaVim.utils.cmd')

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
			---@diagnostic disable-next-line: undefined-field
			-- Ignore RaafatTurki/hex.nvim
			if vim.b.hex then
				vim.g.auto_save_abort = true
				return
			end

			local mode = vim.api.nvim_get_mode()
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
			---@diagnostic disable-next-line: inject-field
			vim.b.Koala_tabs = is_tabs
			if is_tabs then
				vim.opt_local.listchars:append('lead:⋅')
			else
				vim.opt_local.listchars:append('lead: ')
			end
			local tab_size = require('KoalaVim').conf.editor.indent.tab_size
			local n = math.max(tab_size.min, math.min(vim.bo[0].tabstop, tab_size.max))
			vim.bo[0].tabstop = n
		end,
	},
	config = function(_, opts)
		local conf = require('KoalaVim').conf.editor.indent

		-- Override default editorconfig indent size handler by one that cap the tab size to 4
		---@diagnostic disable-next-line: duplicate-set-field
		require('editorconfig').properties.indent_size = function(bufnr, val, ec_opts)
			if val == 'tab' then
				vim.bo[bufnr].shiftwidth = 0
				vim.bo[bufnr].softtabstop = 0
			else
				local n = assert(tonumber(val), 'indent_size must be a number')
				n = math.max(conf.tab_size.min, math.min(n, conf.tab_size.max))

				vim.bo[bufnr].shiftwidth = n
				vim.bo[bufnr].softtabstop = -1
				if not ec_opts.tab_width then
					vim.bo[bufnr].tabstop = n
				end
			end
		end

		require('guess-indent').setup(opts)
	end,
})

local floating_code_ns = api.nvim_create_namespace('Floating Window for Code')
api.nvim_set_hl(floating_code_ns, 'NormalFloat', { link = 'Normal' })

table.insert(M, {
	'ofirgall/NeoZoom.lua', -- fork
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
	cmd = 'NeoZoomToggle',
	keys = {
		{
			'<leader>z',
			function()
				vim.cmd('NeoZoomToggle')
			end,
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
		{
			']t',
			function()
				require('todo-comments').jump_next()
			end,
			desc = 'Next todo comment',
		},
		{
			'[t',
			function()
				require('todo-comments').jump_prev()
			end,
			desc = 'Previous todo comment',
		},
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

		usercmd.create('IPython', 'Open IPython interpreter in split', function()
			require('iron.core').repl_for('python')
			require('iron.core').focus_on('python')
			api.nvim_feedkeys('i', 'n', false)
		end, {})

		usercmd.create('Lua', 'Open Lua interpreter in split', function()
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
	opts = {},
	config = function(_, opts)
		require('color-picker').setup(opts)
	end,
})

table.insert(M, {
	'tiagovla/scope.nvim',
	opts = {},
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
	'gen4438/nvim-FeMaco.lua',
	cmd = 'FeMaco',
	keys = {
		{
			'<leader>e',
			function()
				require('femaco.edit').edit_code_block()
			end,
			'Edit markdown codeblocks',
		},
	},
	opts = {
		post_open_float = function(winnr)
			api.nvim_win_set_hl_ns(winnr, floating_code_ns)
		end,
		float_opts = function(_)
			local width = math.floor(vim.o.columns * 0.65)
			local height = math.floor(vim.o.lines * 0.6)
			local row = math.floor((vim.o.lines - height) / 2)
			local col = math.floor((vim.o.columns - width) / 2)

			return {
				relative = 'editor',
				width = width,
				height = height,
				col = col,
				row = row,
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
		{
			'<leader>gx',
			function()
				require('open').open_cword()
			end,
			desc = 'Open current word',
		},
	},
	opts = {},
	config = function(_, opts)
		require('open').setup(opts)
	end,
	dependencies = {
		{
			'ofirgall/open-jira.nvim',
			config = function(_, opts)
				-- Verify open-jira options
				if not opts.url then
					local koala_opts = require('KoalaVim').conf.plugins.open_jira
					if not require('KoalaVim.conf').verify(koala_opts) then
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
		-- Overriding neovim's default whitespace trim autocmd, clashes with autosave
		---@diagnostic disable-next-line: duplicate-set-field
		require('editorconfig').properties.trim_trailing_whitespace = function() end

		local retrail = require('retrail')
		retrail.setup(opts)
		usercmd.create('TrimWhiteSpace', 'Remove line ending whitespace', function()
			retrail:trim()
		end, {})
	end,
})

table.insert(M, {
	'numToStr/Navigator.nvim',
	opts = {
		disable_on_zoom = false,
	},
	config = function(_, opts)
		require('Navigator').setup(opts)
	end,
	keys = {
		{ '<C-h>', '<cmd>NavigatorLeft<cr>', mode = { 'n', 't' }, desc = 'Navigate left' },
		{ '<C-j>', '<cmd>NavigatorDown<cr>', mode = { 'n', 't' }, desc = 'Navigate down' },
		{ '<C-k>', '<cmd>NavigatorUp<cr>', mode = { 'n', 't' }, desc = 'Navigate up' },
		{ '<C-l>', '<cmd>NavigatorRight<cr>', mode = { 'n', 't' }, desc = 'Navigate right' },
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
		{
			'<leader>H',
			function()
				require('based').convert()
			end,
			mode = { 'n', 'v' },
			desc = 'Convert hex <=> decimal',
		},
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
	opts = {},
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
	'ofirgall/nvim-genghis', -- fork
	cmd = {
		'NewFromSelection',
		'Duplicate',
		'Rename',
		'Trash',
		'Move',
		'CopyFilename',
		'CopyFilepath',
		'CopyRelativePath',
		'CopyDirectoryPath',
		'CopyRelativeDirectoryPath',
		'Chmodx',
		'New',
	},
	config = function()
		vim.g.genghis_use_systemclipboard = true
	end,
})

table.insert(M, {
	'tzachar/highlight-undo.nvim',
	keys = { 'u', '<C-r>' },
	config = function(_, opts)
		require('highlight-undo').setup(opts)
	end,
})

table.insert(M, {
	'AckslD/muren.nvim',
	cmd = {
		'MurenToggle',
		'MurenOpen',
		'MurenClose',
		'MurenFresh',
		'MurenUnique',
	},
	config = function(_, opts)
		require('muren').setup(opts)
	end,
})

table.insert(M, {
	'mbbill/undotree',
	cmd = 'UndotreeToggle',
	config = function()
		vim.g.undotree_WindowLayout = 3
		vim.g.undotree_SplitWidth = 50
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
})

table.insert(M, {
	'ofirgall/interestingwords.nvim', -- fork
	keys = {
		{ '<leader>m', desc = 'Mark (highlight) an interesting word (toggle)', mode = { 'n', 'x' } },
	},
	opts = {
		colors = { '#aeee00', '#ff0000', '#0000ff', '#b88823', '#ffa724', '#ff2c4b' },
		color_key = '<leader>m',
		search_count = false,
		navigation = false,
		search_key = nil,
		cancel_search_key = nil,
		cancel_color_key = nil,
	},
	config = function(_, opts)
		require('interestingwords').setup(opts)
	end,
})

table.insert(M, {
	'ofirgall/trouble.nvim', -- fork
	lazy = true,
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	cmd = { 'TroubleToggle', 'Trouble' },
	keys = {
		{ '<leader>t', '<cmd>TroubleToggle<cr>', desc = 'Toggle Trouble Panel' },
		{ '<leader>xx', '<cmd>TroubleToggle document_diagnostics<cr>', desc = 'Document Diagnostics (Trouble)' },
		{ '<leader>xX', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Workspace Diagnostics (Trouble)' },
		{ '<leader>xl', '<cmd>TroubleToggle loclist<cr>', desc = 'Location List (Trouble)' },
		{ '<leader>xq', '<cmd>TroubleToggle quickfix<cr>', desc = 'Quickfix List (Trouble)' },
		{
			'[q',
			function()
				if require('trouble').is_open() then
					require('trouble').previous({ skip_groups = true, jump = true })
				else
					vim.cmd.cprev()
				end
			end,
			desc = 'Previous trouble/quickfix item',
		},
		{
			']q',
			function()
				if require('trouble').is_open() then
					require('trouble').next({ skip_groups = true, jump = true })
				else
					vim.cmd.cnext()
				end
			end,
			desc = 'Next trouble/quickfix item',
		},
	},
	opts = {
		use_diagnostic_signs = true,
	},
	config = function(_, opts)
		require('trouble').setup(opts)
	end,
})

table.insert(M, {
	'linrongbin16/gitlinker.nvim',
	cmd = 'GitLink',
	config = function(_, opts)
		require('gitlinker').setup(opts)
	end,
})

table.insert(M, {
	'nvim-pack/nvim-spectre',
	lazy = true, -- Used by nvim-tree
	dependencies = {
		'nvim-lua/plenary.nvim',
	},
	cmd = 'FindAndReplace',
	keys = {
		{
			'<leader>fnr',
			function()
				require('spectre').toggle()
			end,
			desc = 'Toggle Find and Replace',
			mode = 'n',
		},
		{
			'<leader>fnc',
			function()
				require('spectre').open_visual({ select_word = true })
			end,
			desc = 'Find and replace current word',
			mode = 'n',
		},
		{
			'<leader>fn',
			'<esc><cmd>lua require("spectre").open_visual()<CR>',
			mode = 'x',
			desc = 'Find and replace selected text',
		},
	},
	config = function(_, opts)
		usercmd.create('FindAndReplace', 'Find and replace text', function()
			require('spectre').toggle(opts)
		end, {})

		HELPERS['spectre_panel'] = '?'
	end,
})

table.insert(M, {
	'chrisgrieser/nvim-puppeteer',
	-- Supported languages
	ft = {
		'python',
		'javascript',
		'typescript',
		'javascriptreact',
		'typescriptreact',
		'vue',
		'astro',
		'lua',
	},
})

table.insert(M, {
	'nkakouros-original/scrollofffraction.nvim',
	event = { 'BufEnter', 'WinEnter', 'WinNew', 'VimResized' },
	opts = {
		scrolloff_fraction = 0.1,
		scrolloff_absolute_filetypes = { 'qf' },
		scrolloff_absolute_value = 0,
	},
	config = function(_, opts)
		require('scrollofffraction').setup(opts)
	end,
})

-- Keep show visual after inserting command mode (:)
table.insert(M, {
	'moyiz/command-and-cursor.nvim',
	event = 'VeryLazy',
	opts = {
		hl_group = 'Visual',
	},
	config = function(_, opts)
		require('command_and_cursor').setup(opts)
	end,
})

table.insert(M, {
	'ofirgall/bracket-repeat.nvim',
	priority = 99999999999, -- load last
	config = function(_, opts)
		require('bracket-repeat').setup(opts)
	end,
})

table.insert(M, {
	'ofirgall/marks.nvim', -- fork
	keys = { 'm' },
	opts = {},
	config = function(_, opts)
		require('marks').setup(opts)
	end,
})

-- FIXME: go over snacks.nvim and replace/add stuff
table.insert(M, {
	'folke/snacks.nvim',
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		bigfile = { enabled = false },
		dashboard = { enabled = false },
		explorer = { enabled = false },
		indent = { enabled = false },
		input = { enabled = false },
		picker = { enabled = false },
		notifier = { enabled = false },
		quickfile = { enabled = false },
		scope = { enabled = false },
		scroll = { enabled = false },
		statuscolumn = { enabled = false },
		words = { enabled = false },
	},
})

return M
