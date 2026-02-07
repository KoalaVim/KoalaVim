-- TODO: lazy load this functions

local api = vim.api
local usercmd = require('KoalaVim.utils.cmd')

local function telescope_default_text(mode)
	if mode == nil then
		return ''
	elseif mode == 'cword' then
		return vim.fn.expand('<cword>')
	elseif mode == 'cWORD' then
		return vim.fn.expand('<cWORD>')
	else
		return require('KoalaVim.utils.text').get_current_line_text(mode)
	end
end

local function find_current_file(find_in_curr_dir)
	local current_file = ''
	if find_in_curr_dir then
		current_file = vim.fn.expand('%:~:.:r')
	else
		current_file = vim.fn.expand('%:t:r')

		-- replace -/_ with spaces to allow fzf find more files
		current_file = current_file:gsub('[-_]', ' ')
	end

	require('telescope.builtin').find_files({
		default_text = current_file,
		hidden = true,
		follow = true,
	})
end

function find_files(mode, cwd)
	require('telescope.builtin').find_files({
		cwd = cwd,
		default_text = telescope_default_text(mode),
	})
end

function live_grep(opts, mode)
	opts = opts or {}
	opts.prompt_title = 'Live Grep Raw (-t[ty] include, -T exclude -g"[!] [glob]")'
	if not opts.default_text then
		opts.default_text = '--hidden -F "' .. telescope_default_text(mode)
	end

	require('telescope').extensions.live_grep_args.live_grep_args(opts)
end

local function live_grep_current_dir(default_text)
	default_text = default_text or ''

	local telescope_text = '-g"' .. vim.fn.fnamemodify(vim.fn.expand('%'), ':.:h') .. '/*"' .. ' -F "' .. default_text

	live_grep({ default_text = telescope_text })
end

-- TODO: convert to lua + make live_grep local
vim.cmd("function! LiveGrepRawOperator(...) \n lua live_grep({}, 'n') \n endfunction") -- used by `<leader>fm`

--------------------------------------------------------------------
-- LSP

local function goto_def()
	local ft = api.nvim_buf_get_option(0, 'filetype')
	if ft == 'man' then
		api.nvim_command(':Man ' .. vim.fn.expand('<cWORD>'))
	elseif ft == 'help' then
		api.nvim_command(':help ' .. vim.fn.expand('<cword>'))
	else
		require('telescope.builtin').lsp_definitions({ show_line = false })
	end
end

local function lsp_references()
	require('telescope.builtin').lsp_references({
		include_declaration = false,
		show_line = false,
	})
end

local function lsp_implementations()
	require('telescope.builtin').lsp_implementations({ show_line = false })
end

local split_if_not_exist = require('KoalaVim.utils.splits').split_if_not_exist

local function open_with_trouble(prompt_bufnr, _mode)
	require('trouble.providers.telescope').smart_open_with_trouble(prompt_bufnr, _mode)
end

local default_file_ignore_patterns = { '\\.git/', 'build/' }
local function get_merged_file_ignore_options()
	local user_file_ignore_patterns = require('KoalaVim').conf.plugins.telescope.additional_file_ignore_patterns
	local file_ignore_patterns = default_file_ignore_patterns

	for _, pattern in ipairs(user_file_ignore_patterns) do
		table.insert(file_ignore_patterns, pattern)
	end

	return file_ignore_patterns
end
---------------------------------------------------------------------

local M = {}

local cycle_layout_list = { 'vertical', 'horizontal' }
local layout = cycle_layout_list[2]
table.insert(M, {
	'nvim-telescope/telescope.nvim',
	cmd = { 'Telescope', 'CmdHistory' },
	lazy = true,
	dependencies = {
		'nvim-lua/plenary.nvim',
		'nvim-telescope/telescope-fzf-native.nvim',
		'nvim-telescope/telescope-ui-select.nvim',
	},
	config = function()
		require('telescope').setup({
			defaults = {
				dynamic_preview_title = true,
				mappings = {
					i = {
						['<C-j>'] = 'move_selection_next',
						['<C-k>'] = 'move_selection_previous',
						['<C-n>'] = 'cycle_history_next',
						['<C-p>'] = 'cycle_history_prev',
						['<C-h>'] = require('telescope.actions.layout').cycle_layout_prev,
						['<C-l>'] = require('telescope.actions.layout').cycle_layout_next,
						['<CR>'] = require('telescope.actions').select_default + require('telescope.actions').center,
						-- stylua: ignore
						['<C-x>'] = require('telescope.actions').select_horizontal + require('telescope.actions').center,
						['<C-v>'] = require('telescope.actions').select_vertical + require('telescope.actions').center,
						['<C-t>'] = require('telescope.actions').select_tab + require('telescope.actions').center,
						['<C-s>'] = require('telescope.actions.layout').toggle_preview,
						['<M-q>'] = open_with_trouble,
					},
					n = {
						['<C-j>'] = 'move_selection_next',
						['<C-k>'] = 'move_selection_previous',
						['<C-h>'] = require('telescope.actions.layout').cycle_layout_prev,
						['<C-l>'] = require('telescope.actions.layout').cycle_layout_next,
						['<C-o>'] = 'select_horizontal',
						['<CR>'] = require('telescope.actions').select_default + require('telescope.actions').center,
						-- stylua: ignore
						['<C-x>'] = require('telescope.actions').select_horizontal + require('telescope.actions').center,
						['<C-v>'] = require('telescope.actions').select_vertical + require('telescope.actions').center,
						['<C-t>'] = require('telescope.actions').select_tab + require('telescope.actions').center,
						['<C-s>'] = require('telescope.actions.layout').toggle_preview,
						['<M-q>'] = open_with_trouble,
					},
				},
				layout_config = {
					horizontal = {
						width = 0.90,
						preview_width = 0.5,
						height = 0.90,
					},
					vertical = {
						-- stylua: ignore
						height = function(_, _, l) return l end,
						width = 0.90,
						preview_height = 0.48,
						prompt_position = 'bottom',
						mirror = true,
					},
				},
				prompt_prefix = ' ',
				layout_strategy = layout,
				cycle_layout_list = cycle_layout_list,
				file_ignore_patterns = get_merged_file_ignore_options(),
			},
			extensions = {
				['ui-select'] = {},
			},
			pickers = {
				find_files = {
					hidden = true,
					follow = true,
					layout_strategy = 'horizontal',
				},
			},
		})

		HELPERS['TelescopePrompt'] = '?'

		-- User Commands
		usercmd.create('CmdHistory', 'Show commands history', function()
			require('telescope.builtin').command_history()
		end, {})
	end,
	keys = {
		-- General telescope utils
		{
			'<leader>fr',
			function()
				require('telescope.builtin').resume({ initial_mode = 'normal' })
			end,
			desc = 'Find resume',
		},
		-- Find files
		{ '<leader>ff', find_files, desc = 'Find file' },
		{ mode = 'v', '<leader>ff', '<Esc><cmd>lua find_files("v")<cr>', desc = 'find file, text from visual' },
		{
			'<leader>fcf',
			function()
				find_files('cword')
			end,
			desc = 'Find files with current word',
		},
		{
			'<leader>o',
			function()
				find_current_file(false)
			end,
			desc = 'find files with the current file (use to find _test fast)',
		},
		{
			'<leader>O',
			function()
				find_current_file(true)
			end,
			desc = 'find files with the current file in the file directory',
		},
		-- Find buffer
		{ '<leader>fb', '<cmd>Telescope buffers<CR>', desc = 'Browse open buffers' },

		----- LSP Bindings -----

		-- Goto definition
		{ 'gd', goto_def, desc = 'Go to Definition' },
		{
			'<MiddleMouse>',
			function()
				vim.api.nvim_input('<LeftMouse>')
				vim.schedule(goto_def)
			end,
			desc = 'Go to Definition in split',
		},
		{
			'<C-LeftMouse>',
			function()
				vim.api.nvim_input('<LeftMouse>')
				vim.api.nvim_input('<cmd>vsplit<cr>')
				vim.schedule(goto_def)
			end,
			desc = 'Go to Definition',
		},
		{
			'gvd',
			function()
				split_if_not_exist(true)
				goto_def()
			end,
			desc = 'Go to Definition in Vsplit',
		},
		{
			'gxd',
			function()
				split_if_not_exist(false)
				goto_def()
			end,
			desc = 'Go to Definition in Xsplit',
		},

		-- Goto references
		{ 'gr', lsp_references, desc = 'Go to References' },
		{
			'gvr',
			function()
				split_if_not_exist(true)
				lsp_references()
			end,
			desc = 'Go to References in Vsplit',
		},
		{
			'gxr',
			function()
				split_if_not_exist(false)
				lsp_references()
			end,
			desc = 'Go to References in Xsplit',
		},

		-- Goto implementations
		{ 'gi', lsp_implementations, desc = 'Go to Implementation' },
		{
			'gvi',
			function()
				split_if_not_exist(true)
				lsp_implementations()
			end,
			desc = 'Go to Implementation in Vsplit',
		},
		{
			'gxi',
			function()
				split_if_not_exist(false)
				lsp_implementations()
			end,
			desc = 'Go to Implementation in Xsplit',
		},

		-- Goto type
		{
			'gt',
			function()
				require('telescope.builtin').lsp_type_definitions()
			end,
			desc = 'Go to Type',
		},
		{
			'gvt',
			function()
				split_if_not_exist(true)
				require('telescope.builtin').lsp_type_definitions({})
			end,
			desc = 'Go to Type in Vsplit',
		},
		{
			'gxt',
			function()
				split_if_not_exist(false)
				require('telescope.builtin').lsp_type_definitions({})
			end,
			desc = 'Go to Type in Xsplit',
		},

		-- Goto symbol
		{
			'gs',
			function()
				require('telescope.builtin').lsp_document_symbols({
					symbol_width = 65,
					symbol_type_width = 8,
					fname_width = 0,
					layout_config = {
						height = 15,
						width = 65 + 8 + 8,
					},
					layout_strategy = 'cursor',
					sorting_strategy = 'ascending', -- From top
					preview = { hide_on_startup = true },
				})
			end,
			desc = 'Go Symbols',
		},
		{
			'<leader>fs',
			function()
				require('telescope.builtin').lsp_dynamic_workspace_symbols()
			end,
			'Find Symbol in workspace',
		},

		-- Go to problem
		{
			'gp',
			function()
				require('telescope.builtin').diagnostics({ bufnr = 0 })
			end,
			desc = 'Go to Problems',
		},
		{
			'gP',
			function()
				require('telescope.builtin').diagnostics()
			end,
			desc = 'Go to workspace Problems',
		},
	},
})

table.insert(M, {
	-- fzf integration for telescope
	'nvim-telescope/telescope-fzf-native.nvim',
	lazy = true,
	build = 'make',
	config = function()
		require('telescope').load_extension('fzf')
	end,
})

table.insert(M, {
	-- native nvim ui select with telescope
	'nvim-telescope/telescope-ui-select.nvim',
	lazy = true,
	config = function()
		require('telescope').load_extension('ui-select')
	end,
})

table.insert(M, {
	-- Better live grep
	'nvim-telescope/telescope-live-grep-args.nvim',
	keys = {
		-- Find word
		{ '<leader>fw', live_grep, desc = 'search in all files (fuzzy finder)' },
		{
			mode = 'v',
			'<leader>fw',
			'<Esc><cmd>lua live_grep({}, "v")<cr>',
			desc = 'search in all files (default text is from visual)',
		},
		{
			'<leader>fcw',
			function()
				live_grep({}, 'cword')
			end,
			desc = 'Find current word',
		},
		{
			'<leader>fcW',
			function()
				live_grep({}, 'cWORD')
			end,
			desc = 'Find current word',
		},
		{ '<leader>fm', ':set opfunc=LiveGrepRawOperator<CR>g@', desc = 'Find with movement' },
		-- Find in current dir
		{ '<leader>fcd', live_grep_current_dir, desc = 'Find in current dir' },
		{
			'<leader>fcdw',
			function()
				live_grep_current_dir(vim.fn.expand('<cword>'))
			end,
			desc = 'Find in current dir current word',
		},
	},
	dependencies = 'nvim-telescope/telescope.nvim',
})

table.insert(M, {
	-- Dictionary with telescope
	'https://code.sitosis.com/rudism/telescope-dict.nvim',
	dependencies = 'nvim-telescope/telescope.nvim',
	keys = {
		{
			'ss',
			function()
				require('telescope.builtin').spell_suggest({
					prompt_title = '',
					layout_config = {
						height = 0.25,
						width = 0.25,
					},
					layout_strategy = 'cursor',
					sorting_strategy = 'ascending', -- From top
				})
			end,
			desc = 'Spell suggest',
		},
		{
			'sy',
			function()
				require('telescope').extensions.dict.synonyms({
					prompt_title = '',
					layout_config = {
						height = 0.4,
						width = 0.60,
					},
					layout_strategy = 'cursor',
					sorting_strategy = 'ascending', -- From top
				})
			end,
			desc = 'Synonyms',
		},
	},
})

table.insert(M, {
	'axkirillov/easypick.nvim',
	dependencies = {
		'nvim-telescope/telescope.nvim',
	},
	keys = {
		{ '<leader>gD', '<cmd>Easypick dirtyfiles<CR>', desc = 'Git dirtyfiles' },
	},
	config = function()
		local easypick = require('easypick')
		easypick.setup({
			pickers = {
				{
					name = 'dirtyfiles',
					command = 'git status -s | cut -c 4-',
					previewer = easypick.previewers.default(),
				},
			},
		})
	end,
})

return M
