-- Helper for folke/trouble.nvim

local function trouble_action(action)
	require('trouble').action(action)
end

HYDRAS['trouble'] = {
	helper = true,
	ft = 'Trouble',
	hint = [[
 _=_: fold toggle          _o_: jump close
 _+_: folds open           _h_: open help
 _-_: folds close

 _m_: toggle mode      _<C-v>_: vert split
 _s_: switch severity  _<C-x>_: horz split

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
		{ 'h', function() trouble_action('open_code_href') end, { exit = true } },
		{ '<C-v>', function() trouble_action('open_vsplit') end, { exit = true } },
		{ '<C-x>', function() trouble_action('open_split') end, { exit = true } },
		{ 'm', function() trouble_action('toggle_mode') end, },
		{ 's', function() trouble_action('switch_severity') end, },
		{ '-', function() trouble_action('close_folds') end, },
		{ '=', function() trouble_action('toggle_fold') end, },
		{ '+', function() trouble_action('open_folds') end, },
		{ 'q', function() trouble_action('cancel') end, { exit = true } },
		{ '<Esc>', function() trouble_action('cancel') end, { exit = true } },
		-- stylua: ignore end
	},
}

return {}
