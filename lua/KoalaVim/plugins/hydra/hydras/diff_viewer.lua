local M = {}

local api = vim.api

local hint = [[
 _j_: next hunk   _J_: next dirty file   _s_: stage hunk
 _k_: prev hunk   _K_: prev dirty file   _r_: reset hunk
 _S_: stage file  _R_: reset file        _u_: undo stage hunk

 ^ ^                 Conflicts
 _<C-k>_: take upper _<C-j>_: take lower _<C-a>_: take both
 ^
		  _<Enter>_: Status  _<Esc>_: exit
]]

HYDRAS['diff_viewer'] = {
	hint = hint,
	config = {
		color = 'pink',
		invoke_on_body = true,
		hint = {
			position = 'bottom',
			border = 'rounded',
		},
		on_enter = function()
			local diff = api.nvim_get_option_value('diff', {})
			if not diff then
				require('inlinediff').enable()
			end
		end,
		on_exit = function()
			local diff = api.nvim_get_option_value('diff', {})
			if not diff then
				require('inlinediff').disable()
			end
		end,
	},
	mode = { 'n', 'x' },
	body = '<leader>gg',
	heads = {
		{
			'j',
			function()
				local diff = api.nvim_get_option_value('diff', {})
				if diff then
					return ']czz'
				end

				require('gitsigns').next_hunk({ navigation_message = false })
				require('KoalaVim.utils.misc').center_screen()
				return '<Ignore>'
			end,
			{ expr = true },
		},
		{
			'k',
			function()
				local diff = api.nvim_get_option_value('diff', {})
				if diff then
					return '[czz'
				end

				require('gitsigns').prev_hunk({ navigation_message = false })
				require('KoalaVim.utils.misc').center_screen()
				return '<Ignore>'
			end,
			{ expr = true },
		},
		{
			'J',
			function()
				require('KoalaVim.utils.git').jump_to_git_dirty_file('next')
				-- require('KoalaVim.utils.misc').center_screen()
				return '<Ignore>'
			end,
			{ expr = true },
		},
		{
			'K',
			function()
				require('KoalaVim.utils.git').jump_to_git_dirty_file('prev')
				-- require('KoalaVim.utils.misc').center_screen()
				return '<Ignore>'
			end,
			{ expr = true },
		},
		{
			's',
			function()
				require('gitsigns').stage_hunk(nil)
				require('gitsigns').next_hunk({ navigation_message = false })
				require('KoalaVim.utils.misc').center_screen()
				return '<Ignore>'
			end,
			{ silent = true },
		},
		{
			'r',
			function()
				require('gitsigns').reset_hunk(nil)
				require('gitsigns').next_hunk({ navigation_message = false })
				require('KoalaVim.utils.misc').center_screen()
				return '<Ignore>'
			end,
			{ silent = true },
		},
		{ 'R', ':Gitsigns reset_buffer<CR>', { silent = true } },
		{
			'u',
			function()
				require('gitsigns').undo_stage_hunk()
			end,
		},
		{
			'S',
			function()
				require('gitsigns').stage_buffer()
			end,
		},
		{
			'<C-k>',
			function()
				require('diffview.actions').conflict_choose('ours')
			end,
		},
		{
			'<C-j>',
			function()
				require('diffview.actions').conflict_choose('theirs')
			end,
		},
		{
			'<C-a>',
			function()
				require('diffview.actions').conflict_choose('all')
			end,
		},
		{
			'<Enter>',
			function()
				require('KoalaVim.utils.git').show_status()
			end,
			{ exit = true },
		},
		-- { 'q', nil, { exit = true, nowait = true } },
		{ '<Esc>', nil, { exit = true, nowait = true } },
	},
}

return M
