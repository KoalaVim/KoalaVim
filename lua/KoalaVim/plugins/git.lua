local M = {}

local api = vim.api

table.insert(M, {
	'lewis6991/gitsigns.nvim',
	branch = 'main',
	event = { 'BufReadPost', 'BufNewFile' },
	cmd = 'Gitsigns',
	opts = {
		add_fg_factor = 0.65,
		sign_priority = 9,
		signcolumn = true,
	},
	config = function(_, opts)
		-- override fg_factor
		for _, highlight in ipairs(require('gitsigns.highlight').hls) do
			for _, info in pairs(highlight) do
				if info.fg_factor then
					info.fg_factor = opts.add_fg_factor
				end
			end
		end
		opts.add_fg_factor = nil -- remove koala param

		local gs = require('gitsigns.actions')
		local DEFER_VAL = 30

		--- Navigate to the next/prev git hunk across files.
		--- First attempts to jump to the next hunk in the current buffer. If the cursor
		--- didn't move (no more hunks in this direction), it jumps to the next dirty file
		--- and navigates to its first/last hunk depending on direction.
		---@param direction 'next'|'prev'
		local function nav(direction)
			local current_line = api.nvim_get_current_line()

			-- Schedule to avoid running during a textlock (e.g. triggered from an expr mapping)
			vim.schedule(function()
				gs.nav_hunk(direction, { navigation_message = false, target = 'all', wrap = false })

				-- Defer to let gitsigns finish the hunk navigation before checking the result
				vim.defer_fn(function()
					-- If the cursor didn't move, there are no more hunks in this file
					if api.nvim_get_current_line() == current_line then
						-- Jump to the next dirty file and navigate to its first/last hunk
						if require('KoalaVim.utils.git').jump_to_git_dirty_file(direction) then
							-- Defer to let the new buffer load before navigating
							vim.defer_fn(function()
								api.nvim_feedkeys(direction == 'next' and 'gg' or 'G', 'n', false)

								-- Schedule to run after feedkeys positions the cursor at gg/G
								vim.schedule(function()
									gs.nav_hunk(direction, { navigation_message = false, target = 'all', wrap = false })
								end)
							end, DEFER_VAL)
						end
					end
				end, DEFER_VAL)
			end)
		end

		if opts.on_attach == nil then
			opts.on_attach = function(bufnr)
				local map_buffer = require('KoalaVim.utils.map').map_buffer

				-- Navigation
				-- TODO: center screen after jump
				map_buffer(bufnr, 'n', ']c', function()
					if vim.wo.diff then
						return ']c'
					end
					nav('next')
					return '<Ignore>'
				end, 'Jump to next git hunk', { expr = true })

				map_buffer(bufnr, 'n', '[c', function()
					if vim.wo.diff then
						return '[c'
					end
					nav('prev')
					return '<Ignore>'
				end, 'Jump to previous git hunk', { expr = true })
				-- Actions
				map_buffer(bufnr, { 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk')
				map_buffer(bufnr, { 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk')
				map_buffer(bufnr, 'n', '<leader>hS', '<cmd>Gitsigns stage_buffer<CR>', 'Stage Buffer')
				map_buffer(bufnr, 'n', '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>', 'Undo Stage')
				map_buffer(bufnr, 'n', '<leader>hR', '<cmd>Gitsigns reset_buffer<CR>', 'Reset Buffer')
				map_buffer(bufnr, 'n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>', 'Preview Hunk')
				map_buffer(bufnr, 'n', '<leader>hb', function()
					-- invalidate cache
					require('gitsigns.cache').cache[api.nvim_get_current_buf()].blame = nil

					require('gitsigns').blame_line({ full = true })
				end, 'Blame Line')
				map_buffer(bufnr, 'n', '<leader>hB', function()
					-- invalidate cache
					require('gitsigns.cache').cache[api.nvim_get_current_buf()].blame = nil

					require('gitsigns').blame_line({ full = true, extra_opts = { '-C' } })
				end, 'Blame Line with detect copied (moved) code. adds `-C` for git blame')
				map_buffer(bufnr, 'n', '<leader>hd', '<cmd>Gitsigns toggle_deleted<CR>', 'Toggle Deleted Virtual Text')
				-- Text object
				map_buffer(bufnr, { 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'Select Hunk')
			end
		end

		require('gitsigns').setup(opts)
	end,
})

table.insert(M, {
	'ofirgall/neogit',
	enabled = function()
		return vim.env.NEOGIT
	end,
	lazy = true,
	dependencies = {
		'nvim-lua/plenary.nvim', -- required
		'sindrets/diffview.nvim', -- optional - Diff integration
	},
	cmd = 'Neogit',
	keys = {
		{
			'<leader>gs',
			function()
				require('neogit').open({ kind = 'floating' })
			end,
			desc = 'Open Neogit (git status)',
		},
	},
	opts = {
		-- TODO: try kitty style
		-- graph_style = 'unicode',
		-- TODO: config
		signs = {
			-- { CLOSED, OPENED }
			hunk = { '', '' },
			item = { '>', 'v' },
			section = { '>', 'v' },
		},
		floating = {
			relative = 'editor',
			width = 0.8,
			height = 0.8,
			-- style = 'minimal',
			border = 'rounded',
		},
		commit_editor = {
			kind = 'floating',
		},
		mappings = {
			popup = {
				['p'] = 'PushPopup',
				['P'] = 'PullPopup',
				['l'] = false,
				['t'] = 'LogPopup', -- tree
				['T'] = 'TagPopup',
			},
			status = {
				['='] = 'Toggle',
				['l'] = 'Toggle',
				['h'] = 'Toggle',
				['<Esc>'] = 'Close',
				['J'] = 'NextSection',
				['K'] = 'PreviousSection',
			},
		},
	},
	config = function(_, opts)
		require('neogit').setup(opts)
	end,
})

local function is_floating(win)
	win = win or vim.api.nvim_get_current_win()
	local config = vim.api.nvim_win_get_config(win)
	return config.relative ~= ''
end

local function git_to_floating_window(buf)
	local orig_win = vim.api.nvim_get_current_win()
	if is_floating(orig_win) then
		return
	end

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.75)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local new_win = vim.api.nvim_open_win(buf, true, {
		relative = 'editor',
		width = width,
		height = height,
		row = row,
		col = col,
		style = 'minimal',
		border = 'rounded',
	})

	-- Autoclose the floating window.
	-- TODO: delete buffer?
	api.nvim_create_autocmd('WinLeave', {
		once = true,
		callback = function()
			if vim.api.nvim_get_current_win() ~= new_win then
				return
			end
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(new_win) then
					vim.api.nvim_win_close(new_win, false)
				end
			end)
		end,
	})

	vim.keymap.set('n', 'q', '<cmd>q<CR>', { buffer = buf })
	vim.schedule(function()
		vim.api.nvim_set_current_win(new_win)
		vim.api.nvim_win_close(orig_win, false)
		-- FIXME: support not ofirkai themes
		require('KoalaVim.utils.windows').set_option(new_win, 'winhighlight', 'FloatBorder:FloatBorderNotHidden')
	end)
end

local _fugitive_keys = {
	{ '<leader>gc', '<cmd>Git commit<CR>', desc = 'Git commit' },
	{ '<leader>gac', '<cmd>Git commit --amend<CR>', desc = 'Git commit --amend' },
	{ '<leader>gp', '<cmd>Git push<CR>', desc = 'Git push' },
	{ '<leader>gP', '<cmd>Git push --force<CR>', desc = 'Git push force' },
}

if not vim.env.NEOGIT then
	table.insert(_fugitive_keys, { '<leader>gs', '<cmd>G<CR>', desc = 'Open fugitive.vim (git status)' })
end

table.insert(M, {
	'tpope/vim-fugitive',
	keys = _fugitive_keys,
	cmd = { 'Git', 'G' },
	config = function()
		-- Jump to first group of files
		api.nvim_create_autocmd('BufWinEnter', {
			callback = function(events)
				if vim.bo[events.buf].ft ~= 'fugitive' then
					return
				end

				local first_line = api.nvim_buf_get_lines(events.buf, 0, 1, true)[1]
				if first_line:match('Head: ') then
					api.nvim_feedkeys('}j', 'n', false)
				end
			end,
		})

		local fugitive_window_is_active = false

		api.nvim_create_autocmd('FileType', {
			pattern = { 'fugitive', 'gitcommit' },
			callback = function(events)
				git_to_floating_window(events.buf)

				-- Focus back to fugitive on finishing commiting
				if vim.bo[events.buf].ft == 'gitcommit' then
					api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
						once = true,
						buffer = events.buf,
						callback = function()
							if fugitive_window_is_active then
								vim.cmd(':G') -- focus fugitive back
							end
						end,
					})
				elseif vim.bo[events.buf].ft == 'fugitive' then
					fugitive_window_is_active = true
					api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
						once = true,
						buffer = events.buf,
						callback = function()
							fugitive_window_is_active = false
						end,
					})
				end
			end,
		})
	end,
})

table.insert(M, {
	'sindrets/diffview.nvim',
	cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
	keys = {
		{ '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Git show diff' },
		{ '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'Git file History' },
		{ '<leader>gH', '<cmd>DiffviewFileHistory .<CR>', desc = 'Git workspace History' },
		{
			'gh',
			'<Esc><cmd>lua require("KoalaVim.utils.git").show_history("v")<cr>',
			mode = 'v',
			desc = 'Show Git History of the visual selection',
		},
	},
	config = function()
		local actions = require('diffview.actions')
		local function next_file()
			actions.select_next_entry()
			actions.refresh_files()
		end

		local function prev_file()
			actions.select_prev_entry()
			actions.refresh_files()
		end

		-- FIXME: hook to diffview create/close to clear the autocmd
		-- Auto execute ]c when entering a new diff buffer
		local jumped = {}
		vim.api.nvim_create_autocmd('BufEnter', {
			callback = vim.schedule_wrap(function(ev)
				if not vim.api.nvim_buf_is_valid(ev.buf) then
					return
				end

				local name = vim.api.nvim_buf_get_name(ev.buf)
				if not vim.wo[vim.api.nvim_get_current_win()].diff then
					-- ignore not diff files
					return
				end

				-- Don't jump again if buffer already being jumped
				if jumped[ev.buf] then
					return
				end

				if name:match('^diffview://') ~= nil then
					-- Don't send ]c to diffview files (compared old files)
					return
				end

				jumped[ev.buf] = true
				vim.schedule(function()
					api.nvim_feedkeys(']c', 'n', false)
				end)
			end),
		})

		require('diffview').setup({
			watch_index = false,
			enhanced_diff_hl = true,
			file_history_panel = {
				log_options = {
					git = {
						single_file = {
							follow = true,
						},
					},
				},
			},
			key_bindings = {
				view = {
					{ 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' } },
					{ 'n', '<M-n>', actions.focus_files, { desc = 'Focus files panel' } },
					{ 'n', '<M-m>', actions.toggle_files, { desc = 'Toggle files panel' } },
					{ 'n', '<leader>ck', actions.conflict_choose('ours'), { desc = 'Choose OURS (up) conflict' } },
					{ 'n', '<leader>cj', actions.conflict_choose('theirs'), { desc = 'Choose OURS (down) conflict' } },
					{ 'n', '<tab>', next_file, { desc = 'Select next file' } },
					{ 'n', '<s-tab>', prev_file, { desc = 'Select prev file' } },
					{ 'n', '<M-n>', next_file, { desc = 'Select prev file' } },
					{ 'n', '<M-p>', prev_file, { desc = 'Select next file' } },
					{ 'n', '<M-j>', ']c', { desc = 'Next change' } },
					{ 'n', '<M-k>', '[c', { desc = 'Next change' } },
					{ 'n', '<C-g>', actions.cycle_layout, { desc = 'Cycle layout' } },
					{ 'n', '<M-s>', '<cmd>Gitsigns stage_buffer<CR>', { desc = 'Stage change' } },
					{ 'n', '<M-u>', '<cmd>Gitsigns undo_stage_hunk<CR>', { desc = 'Undo Stage change' } },
					{ 'n', '<M-r>', '<cmd>Gitsigns reset_hunk<CR>', { desc = 'Reset change' } },
				},
				file_panel = {
					{ 'n', 'cc', '<cmd>Git commit<cr>', { desc = 'Stage file' } },
					{ 'n', 's', actions.toggle_stage_entry, { desc = 'Stage file' } },
					{ 'n', '=', actions.toggle_stage_entry, { desc = 'Stage file' } },
					{ 'n', 'q', actions.close, { desc = 'Close' } },
					{ 'n', 'gf', actions.goto_file_edit, { desc = 'Close' } },
					{ 'n', '<M-n>', actions.focus_files, { desc = 'Focus files panel' } },
					{ 'n', '<M-m>', actions.toggle_files, { desc = 'Toggle files panel' } },
					{ 'n', '<tab>', next_file, { desc = 'Select next file' } },
					{ 'n', '<s-tab>', prev_file, { desc = 'Select prev file' } },
					{ 'n', '<M-n>', next_file, { desc = 'Select next file' } },
					{ 'n', '<M-p>', prev_file, { desc = 'Select prev file' } },
					{ 'n', '<C-g>', actions.cycle_layout, { desc = 'Cycle layout' } },
				},
				file_history_panel = {
					{ 'n', 's', actions.open_in_diffview, { desc = 'Show full commit diff in diffview' } },
					{ 'n', 'S', actions.open_commit_log, { desc = 'Show commit details' } },
					{ 'n', 'q', actions.close, { desc = 'Close' } },
					{ 'n', 'gf', actions.goto_file_edit, { desc = 'Open the file in the previous tabpage' } },
					{ 'n', '<M-n>', actions.focus_files, { desc = 'Focus on file panel' } },
					{ 'n', '<M-m>', actions.toggle_files, { desc = 'Toggle file panel' } },
					{ 'n', '<C-g>', actions.cycle_layout, { desc = 'Cycle layout' } },
					-- disable binds
					['zo'] = false,
					['zM'] = false,
					['h'] = false,
					['zc'] = false,
					['zR'] = false,
					['za'] = false,
					['g<C-x>'] = false,
					['<C-A-d>'] = false,
					['X'] = false,
					['<leader>b'] = false,
				},
				-- TODO: close commit_log_panel with 'q'
			},
			view = {
				default = {
					layout = 'diff2_horizontal',
				},
				merge_tool = {
					layout = 'diff4_mixed',
					disable_diagnostics = true,
				},
				file_history = {
					layout = 'diff2_horizontal',
				},
			},
			commit_log_panel = {
				win_config = {
					height = 30,
				},
			},
			file_panel = {
				win_config = {
					position = 'bottom',
					height = 10,
				},
			},
			hooks = {
				view_opened = function(view)
					-- Auto focus on right side panel
					vim.defer_fn(function()
						vim.api.nvim_command('wincmd k')
						vim.api.nvim_command('wincmd l')
					end, 300)
				end,
			},
		})

		HELPERS['DiffviewFileHistory'] = 'g?'
		HELPERS['DiffviewFiles'] = 'g?'
	end,
})

table.insert(M, {
	'rhysd/git-messenger.vim',
	keys = {
		{ '<leader>hh', '<cmd>GitMessenger<CR>', desc = 'Hunk history' },
	},
	dependencies = {
		'tpope/vim-fugitive',
	},
	config = function()
		vim.g.git_messenger_floating_win_opts = { border = 'single' }
		vim.g.git_messenger_popup_content_margins = false
		vim.g.git_messenger_always_into_popup = true
		vim.g.git_messenger_no_default_mappings = true
		api.nvim_create_autocmd('FileType', {
			pattern = { 'gitmessengerpopup', 'git' },
			callback = function()
				---@diagnostic disable-next-line: param-type-mismatch
				vim.call('fugitive#MapJumps') -- map jumps to hunks/changes like fugitive
				-- remove overlapping maps from fugitive
				vim.keymap.del('n', 'dq', { buffer = 0 })
				vim.keymap.del('n', 'r<Space>', { buffer = 0 })
				vim.keymap.del('n', 'r<CR>', { buffer = 0 })
				vim.keymap.del('n', 'ri', { buffer = 0 })
				vim.keymap.del('n', 'rf', { buffer = 0 })
				vim.keymap.del('n', 'ru', { buffer = 0 })
				vim.keymap.del('n', 'rp', { buffer = 0 })
				vim.keymap.del('n', 'rw', { buffer = 0 })
				vim.keymap.del('n', 'rm', { buffer = 0 })
				vim.keymap.del('n', 'rd', { buffer = 0 })
				vim.keymap.del('n', 'rk', { buffer = 0 })
				vim.keymap.del('n', 'rx', { buffer = 0 })
				vim.keymap.del('n', 'rr', { buffer = 0 })
				vim.keymap.del('n', 'rs', { buffer = 0 })
				vim.keymap.del('n', 're', { buffer = 0 })
				vim.keymap.del('n', 'ra', { buffer = 0 })
				vim.keymap.del('n', 'r?', { buffer = 0 })

				-- add overridden maps
				vim.keymap.set('n', 'o', '<cmd>call b:__gitmessenger_popup.opts.mappings["o"][0]()<CR>', { buffer = 0 })
				vim.keymap.set('n', 'i', '<cmd>call b:__gitmessenger_popup.opts.mappings["O"][0]()<CR>', { buffer = 0 })
			end,
		})
	end,
})

table.insert(M, {
	'ofirgall/commit-prefix.nvim',
	ft = 'gitcommit',
	config = function()
		require('commit-prefix').setup()
	end,
})

table.insert(M, {
	'rbong/vim-flog',
	dependencies = {
		'tpope/vim-fugitive',
	},
	cmd = { 'Flog', 'Flogsplit', 'Floggit' },
	keys = {
		{ '<leader>gt', '<cmd>vert Flogsplit<CR>', desc = 'Git Tree (vsplit)' },
		{ '<leader>gT', '<cmd>Flog<CR>', desc = 'Git Tree (tabnew)' },
		{ '<leader>got', '<cmd>Flogsplit<CR>', desc = 'Git Tree (split)' },
	},
	config = function()
		vim.g.flog_default_opts = {
			max_count = 512,
			date = 'short',
		}

		local function get_flog_commit(line)
			return vim.call('flog#floggraph#commit#GetAtLine', line)['hash']
		end

		local function flog_current_commit()
			return get_flog_commit('.')
		end

		local function flog_commit_range_visual()
			local start_pos = api.nvim_buf_get_mark(0, '<')
			local end_pos = api.nvim_buf_get_mark(0, '>')

			local start_commit = get_flog_commit(start_pos[1])
			local end_commit = get_flog_commit(end_pos[1])

			return {
				start_commit,
				end_commit,
			}
		end

		local function flog_diff_current()
			vim.cmd('DiffviewOpen ' .. flog_current_commit() .. '^')
		end

		function flog_diff_current_visual()
			local commits = flog_commit_range_visual()
			vim.cmd('DiffviewOpen ' .. commits[2] .. '^..' .. commits[1])
		end

		local function flog_show_current()
			vim.cmd('DiffviewOpen ' .. flog_current_commit() .. '^..' .. flog_current_commit())
		end

		local map_buffer = require('KoalaVim.utils.map').map_buffer

		api.nvim_create_autocmd('FileType', {
			pattern = 'floggraph',
			callback = function(events)
				-- stylua: ignore start
				map_buffer(events.buf, 'n', '<C-d>', flog_diff_current, 'Floggraph: show diff from head to current')
				map_buffer(events.buf, 'x', '<C-d>', '<Esc><cmd>lua flog_diff_current_visual()<cr>', 'Floggraph: show diff of selection')
				map_buffer(events.buf, 'x', '<C-s>', '<Esc><cmd>lua flog_diff_current_visual()<cr>', 'Floggraph: show diff of selection')
				map_buffer(events.buf, 'n', '<C-s>', flog_show_current, 'Floggraph: show current in diffview')
				-- stylua: ignore end

				-- Delete flog's gq
				vim.keymap.del('n', 'gq', { buffer = events.buf })
			end,
		})
	end,
})

table.insert(M, {
	'pwntester/octo.nvim',
	cmd = 'Octo',
	event = { { event = 'BufReadCmd', pattern = 'octo://*' } },
	opts = {
		enable_builtin = true,
		-- FIXME: add `gh auth refresh -s read:project` to README.md
		default_to_projects_v2 = true,
		default_merge_method = 'squash',
		picker = 'telescope',
	},
	keys = {
		{ '<leader>gil', '<cmd>Octo issue list<CR>', desc = 'List Issues (Octo)' },
		{ '<leader>gic', '<cmd>Octo issue create<CR>', desc = 'List Issues (Octo)' },
		{ '<leader>gI', '<cmd>Octo issue search<CR>', desc = 'Search Issues (Octo)' },
		{ '<leader>gr', '<cmd>Octo pr list<CR>', desc = 'List PRs (Octo)' },
		{ '<leader>gR', '<cmd>Octo pr search<CR>', desc = 'Search PRs (Octo)' },
		{ '<leader>gl', '<cmd>Octo repo list<CR>', desc = 'List Repos (Octo)' },
		{ '<leader>gS', '<cmd>Octo search<CR>', desc = 'Search (Octo)' },

		{ '<localleader>a', '', desc = '+assignee (Octo)', ft = 'octo' },
		{ '<localleader>c', '', desc = '+comment/code (Octo)', ft = 'octo' },
		{ '<localleader>l', '', desc = '+label (Octo)', ft = 'octo' },
		{ '<localleader>i', '', desc = '+issue (Octo)', ft = 'octo' },
		{ '<localleader>r', '', desc = '+react (Octo)', ft = 'octo' },
		{ '<localleader>p', '', desc = '+pr (Octo)', ft = 'octo' },
		{ '<localleader>pr', '', desc = '+rebase (Octo)', ft = 'octo' },
		{ '<localleader>ps', '', desc = '+squash (Octo)', ft = 'octo' },
		{ '<localleader>v', '', desc = '+review (Octo)', ft = 'octo' },
		{ '<localleader>g', '', desc = '+goto_issue (Octo)', ft = 'octo' },
		{ '@', '@<C-x><C-o>', mode = 'i', ft = 'octo', silent = true },
		{ '#', '#<C-x><C-o>', mode = 'i', ft = 'octo', silent = true },
	},
	config = function(_, opts)
		require('octo').setup(opts)
	end,
})

return M
