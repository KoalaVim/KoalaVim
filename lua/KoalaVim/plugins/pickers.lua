local api = vim.api
local usercmd = require('KoalaVim.utils.cmd')

-- ── Helpers ──────────────────────────────────────────────────────────

local function get_visual_text()
	return require('KoalaVim.utils.text').get_current_line_text('v')
end

local function find_current_file(find_in_curr_dir)
	local current_file = ''
	if find_in_curr_dir then
		current_file = vim.fn.expand('%:~:.:r')
	else
		current_file = vim.fn.expand('%:t:r')
		current_file = current_file:gsub('[-_]', ' ')
	end

	require('fff').find_files({ query = current_file })
end

local function find_files(mode, cwd)
	local query = ''
	if mode == 'cword' then
		query = vim.fn.expand('<cword>')
	elseif mode == 'cWORD' then
		query = vim.fn.expand('<cWORD>')
	elseif mode == 'v' then
		query = get_visual_text()
	end

	require('fff').find_files({ query = query, cwd = cwd })
end

local function live_grep(opts, mode)
	opts = opts or {}

	if not opts.query then
		local text = ''
		if mode == 'cword' then
			text = vim.fn.expand('<cword>')
		elseif mode == 'cWORD' then
			text = vim.fn.expand('<cWORD>')
		elseif mode == 'v' then
			text = get_visual_text()
		elseif mode == 'n' then
			text = require('KoalaVim.utils.text').get_current_line_text('n')
		end
		if text ~= '' then
			opts.query = text
		end
	end

	require('fff').live_grep(opts)
end

local function live_grep_current_dir(default_text)
	local dir = vim.fn.fnamemodify(vim.fn.expand('%'), ':.:h')
	local opts = { cwd = dir }
	if default_text and default_text ~= '' then
		opts.query = default_text
	end
	require('fff').live_grep(opts)
end

vim.cmd("function! LiveGrepRawOperator(...) \n lua live_grep({}, 'n') \n endfunction")

-- ── LSP (via snacks.picker) ─────────────────────────────────────────

local function goto_def()
	local ft = api.nvim_buf_get_option(0, 'filetype')
	if ft == 'man' then
		api.nvim_command(':Man ' .. vim.fn.expand('<cWORD>'))
	elseif ft == 'help' then
		api.nvim_command(':help ' .. vim.fn.expand('<cword>'))
	else
		Snacks.picker.lsp_definitions()
	end
end

local function lsp_references()
	Snacks.picker.lsp_references()
end

local function lsp_implementations()
	Snacks.picker.lsp_implementations()
end

local split_if_not_exist = require('KoalaVim.utils.splits').split_if_not_exist

-- ── Plugin specs ─────────────────────────────────────────────────────

local M = {}

-- fff — file finder and content grep
table.insert(M, {
	'dmtrKovalenko/fff.nvim',
	build = function()
		require('fff.download').download_or_build_binary()
	end,
	lazy = false,
	opts = {
		prompt_vim_mode = true,
		keymaps = {
			move_down = { '<Down>', '<C-j>' },
			move_up = { '<Up>', '<C-k>' },
			select_split = '<C-x>',
			select_vsplit = '<C-v>',
			select_tab = '<C-t>',
			send_to_quickfix = '<M-q>',
		},
		layout = {
			height = 0.9,
			width = 0.9,
			preview_size = 0.5,
			prompt_position = 'bottom',
		},
		hl = {
			normal = 'FffNormal',
			border = 'FffBorder',
			title = 'FffTitle',
			prompt = 'FffPrompt',
			cursorline = 'FffCursorLine',
			matched = 'FffMatched',
			selected = 'FffSelected',
			selected_active = 'FffSelectedActive',
			frecency = 'FffFrecency',
			directory_path = 'FffDirectory',
			winhl = {
				preview = 'Normal:FffPreviewNormal,FloatBorder:FffPreviewBorder,FloatTitle:FffPreviewTitle',
			},
		},
	},
	keys = {
		-- Find files
		{ '<leader>ff', find_files, desc = 'Find file' },
		{ mode = 'v', '<leader>ff', '<Esc><cmd>lua find_files("v")<cr>', desc = 'Find file, text from visual' },
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
			desc = 'Find files with the current file (use to find _test fast)',
		},
		{
			'<leader>O',
			function()
				find_current_file(true)
			end,
			desc = 'Find files with the current file in the file directory',
		},

		-- Find word (grep)
		{ '<leader>fw', live_grep, desc = 'Search in all files (live grep)' },
		{
			mode = 'v',
			'<leader>fw',
			function()
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
				live_grep({}, 'v')
			end,
			desc = 'Search in all files (default text is from visual)',
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
			desc = 'Find current WORD',
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

		-- Find buffer (snacks)
		{
			'<leader>fb',
			function()
				Snacks.picker.buffers()
			end,
			desc = 'Browse open buffers',
		},

		-- Resume last picker (snacks)
		{
			'<leader>fr',
			function()
				Snacks.picker.resume()
			end,
			desc = 'Find resume',
		},

		----- LSP Bindings -----

		-- Goto definition
		{ 'gd', goto_def, desc = 'Go to Definition' },
		{
			'<MiddleMouse>',
			function()
				vim.api.nvim_input('<LeftMouse>')
				vim.schedule(goto_def)
			end,
			desc = 'Go to Definition',
		},
		{
			'<C-LeftMouse>',
			function()
				vim.api.nvim_input('<LeftMouse>')
				vim.api.nvim_input('<cmd>vsplit<cr>')
				vim.schedule(goto_def)
			end,
			desc = 'Go to Definition in split',
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
				Snacks.picker.lsp_type_definitions()
			end,
			desc = 'Go to Type',
		},
		{
			'gvt',
			function()
				split_if_not_exist(true)
				Snacks.picker.lsp_type_definitions()
			end,
			desc = 'Go to Type in Vsplit',
		},
		{
			'gxt',
			function()
				split_if_not_exist(false)
				Snacks.picker.lsp_type_definitions()
			end,
			desc = 'Go to Type in Xsplit',
		},

		-- Goto symbol (snacks) — small cursor-anchored picker like telescope had
		{
			'gs',
			function()
				local pos = vim.fn.screenpos(0, vim.fn.line('.'), vim.fn.col('.'))
				Snacks.picker.lsp_symbols({
					layout = {
						preview = false,
						reverse = false,
						layout = {
							box = 'vertical',
							border = true,
							title = '{title}',
							title_pos = 'center',
							width = 100,
							height = 15,
							row = pos.row,
							col = pos.col,
							{ win = 'input', height = 1, border = 'bottom' },
							{ win = 'list', border = 'none' },
						},
					},
				})
			end,
			desc = 'Go Symbols',
		},
		{
			'<leader>fs',
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = 'Find Symbol in workspace',
		},

		-- Go to problem (snacks diagnostics)
		{
			'gp',
			function()
				Snacks.picker.diagnostics_buffer()
			end,
			desc = 'Go to Problems',
		},
		{
			'gP',
			function()
				Snacks.picker.diagnostics()
			end,
			desc = 'Go to workspace Problems',
		},
	},
})

-- User Commands
usercmd.create('CmdHistory', 'Show commands history', function()
	Snacks.picker.command_history()
end, {})

-- Dirty files via snacks git_status (replaces easypick)
usercmd.create('GitDirtyFiles', 'Show git dirty files', function()
	Snacks.picker.git_status()
end, {})

-- ── Spell/synonyms (snacks pickers) ─────────────────────────────────

-- Spell suggest via snacks
table.insert(M, {
	'folke/snacks.nvim',
	keys = {
		{
			'ss',
			function()
				local pos = vim.fn.screenpos(0, vim.fn.line('.'), vim.fn.col('.'))
				Snacks.picker.spelling({
					layout = {
						preview = false,
						reverse = false,
						layout = {
							box = 'vertical',
							border = true,
							title = '{title}',
							title_pos = 'center',
							width = 40,
							height = 10,
							row = pos.row,
							col = pos.col,
							{ win = 'input', height = 1, border = 'bottom' },
							{ win = 'list', border = 'none' },
						},
					},
				})
			end,
			desc = 'Spell suggest',
		},
	},
})

-- GAP: telescope-dict synonyms picker (bound to `sy`) has no snacks equivalent.
-- Synonyms require a dictionary data source that neither fff nor snacks provide.

-- ── Git dirty files keybind (replaces easypick) ─────────────────────

table.insert(M, {
	'folke/snacks.nvim',
	keys = {
		{
			'<leader>gD',
			function()
				Snacks.picker.git_status()
			end,
			desc = 'Git dirtyfiles',
		},
	},
})

return M
