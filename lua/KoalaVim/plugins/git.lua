local M = {}

local api = vim.api

table.insert(M, {
	'lewis6991/gitsigns.nvim',
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

		local gs = require('gitsigns')
		if opts.on_attach == nil then
			opts.on_attach = function(bufnr)
				local map_buffer = require('KoalaVim.utils.map').map_buffer

				-- Navigation
				-- TODO: center screen after jump
				map_buffer(bufnr, 'n', ']c', function()
					if vim.wo.diff then
						return ']c'
					end
					vim.schedule(function()
						gs.next_hunk({ navigation_message = false })
					end)
					return '<Ignore>'
				end, 'Jump to next git hunk', { expr = true })

				map_buffer(bufnr, 'n', '[c', function()
					if vim.wo.diff then
						return '[c'
					end
					vim.schedule(function()
						gs.prev_hunk({ navigation_message = false })
					end)
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

		gs.setup(opts)
	end,
})

table.insert(M, {
	'tpope/vim-fugitive',
	keys = {
		{ '<leader>gs', '<cmd>:G<CR>', desc = 'Open fugitive.vim (git status)' },
		{ '<leader>gp', '<cmd>Git push<CR>', desc = 'Git push' },
		{ '<leader>gP', '<cmd>Git push --force<CR>', desc = 'Git push force' },
	},
	cmd = { 'Git', 'G' },
	config = function()
		-- Jump to first group of files
		api.nvim_create_autocmd('BufWinEnter', {
			callback = function(events)
				local ft = api.nvim_buf_get_option(events.buf, 'filetype')
				if ft ~= 'fugitive' then
					return
				end

				local first_line = api.nvim_buf_get_lines(events.buf, 0, 1, true)[1]
				if first_line:match('Head: ') then
					api.nvim_feedkeys('}j', 'n', false)
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
		local cb = require('diffview.config').diffview_callback
		local actions = require('diffview.actions')
		require('diffview').setup({
			watch_index = false,
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
					['q'] = '<cmd>:DiffviewClose<cr>',
					['<M-n>'] = actions.focus_files,
					['<M-m>'] = actions.toggle_files,
					['<leader>ck'] = actions.conflict_choose('ours'),
					['<leader>cj'] = actions.conflict_choose('theirs'),
					['<tab>'] = function()
						actions.select_next_entry()
						actions.refresh_files()
					end,
					['<s-tab>'] = function()
						actions.select_prev_entry()
						actions.refresh_files()
					end,
				},
				file_panel = {
					-- TODO: description for binds
					-- TODO: unbind unnecessary
					['s'] = cb('toggle_stage_entry'),
					['q'] = cb('close'),
					['gf'] = cb('goto_file_edit'),
					['<M-n>'] = cb('focus_files'),
					['<M-m>'] = actions.toggle_files,
				},
				file_history_panel = {
					{ 'n', 's', cb('open_in_diffview'), { desc = 'Show full commit diff in diffview' } },
					{ 'n', 'S', cb('open_commit_log'), { desc = 'Show commit details' } },
					{ 'n', 'q', cb('close'), { desc = 'Close' } },
					{ 'n', 'gf', cb('goto_file_edit'), { desc = 'Open the file in the previous tabpage' } },
					{ 'n', '<M-n>', cb('focus_files'), { desc = 'Focus on file panel' } },
					{ 'n', '<M-m>', cb('toggle_files'), { desc = 'Toggle file panel' } },
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
					height = 30
				},
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
	config = function(_, opts)
		require('octo').setup(opts)
	end,
})

table.insert(M, {
	'SuperBo/fugit2.nvim',
	dependencies = {
		'MunifTanjim/nui.nvim',
		'nvim-tree/nvim-web-devicons',
		'nvim-lua/plenary.nvim',
		{
			'chrisgrieser/nvim-tinygit', -- optional: for Github PR view
			dependencies = { 'stevearc/dressing.nvim' },
		},
	},
	cmd = { 'Fugit2', 'Fugit2Diff', 'Fugit2Graph', 'Fugit2Blame' },
	keys = {
		{ '<leader>gS', mode = 'n', '<cmd>Fugit2<cr>' },
	},
	opts = {
		width = '90%',
		height = '90%',
	},
	config = function(_, opts)
		require('fugit2').setup(opts)
	end,
})

return M
