-- Search register before the hydra started, restored on exit
local orig_search = nil

local function nav(search_char)
	if orig_search == nil then
		orig_search = vim.fn.getreg('/')
	end
	require('KoalaVim.utils.ai.general').nav_to_prompt(search_char)
end

HYDRAS['Goto prompts'] = {
	hint = [[
 _k_: prev prompt
 _j_: next prompt
  _<Esc>_
	]],
	config = {
		on_exit = function()
			if orig_search ~= nil then
				vim.fn.setreg('/', orig_search)
				orig_search = nil
			end
		end,
		hint = {
			border = 'rounded',
		},
	},
	mode = 'n',
	heads = {
		{ 'j', function() nav('n') end },
		{ 'k', function() nav('N') end },
		--
		{ '<Esc>', nil, { exit = true } },
	},
	custom_bodies = {
		{
			'gj',
			mode = 'n',
			ft = 'sidekick_terminal',
			desc = 'Go to next prompt',
			callback = function(hydra)
				nav('n')
				hydra:activate()
			end,
		},
		{
			'gk',
			mode = 'n',
			ft = 'sidekick_terminal',
			desc = 'Go to previous prompt',
			callback = function(hydra)
				nav('N')
				hydra:activate()
			end,
		},
	},
}

return {}
