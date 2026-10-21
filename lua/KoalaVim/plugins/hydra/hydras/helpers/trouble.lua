-- Helper for folke/trouble.nvim

-- Runs a trouble action (name or key of the view's `keys`) on the view of the current window
local function trouble_action(action)
	local win = vim.api.nvim_get_current_win()
	for _, v in ipairs(require('trouble.view').get({ open = true })) do
		if v.view.win.win == win then
			v.view:action(v.view.opts.keys[action] or action)
			return
		end
	end
end

HYDRAS['trouble'] = {
	helper = true,
	ft = 'trouble',
	hint = [[
 _=_: fold toggle          _o_: jump close
 _+_: folds open           _h_: open help
 _-_: folds close

 _s_: switch severity  _<C-v>_: vert split
                       _<C-x>_: horz split

 ^ ^    _<Esc>_: cancel   _q_: cancel
]],
	config = {
		color = 'pink',
		hint = {
			position = 'middle-right',
			border = 'single',
			offset = 10,
		},
	},
	mode = 'n',
	heads = {
		-- stylua: ignore start
		{ 'o', function() trouble_action('jump_close') end, { exit = true } },
		{ 'h', function() trouble_action('help') end, { exit = true } },
		{ '<C-v>', function() trouble_action('jump_vsplit') end, { exit = true } },
		{ '<C-x>', function() trouble_action('jump_split') end, { exit = true } },
		{ 's', function() trouble_action('s') end, },
		{ '-', function() trouble_action('fold_close_all') end, },
		{ '=', function() trouble_action('fold_toggle') end, },
		{ '+', function() trouble_action('fold_open_all') end, },
		{ 'q', function() trouble_action('cancel') end, { exit = true } },
		{ '<Esc>', function() trouble_action('cancel') end, { exit = true } },
		-- stylua: ignore end
	},
}

return {}
