local M = {}

local name = 'multi-cursors'
local c = 0

local bodies = {
	{
		'<M-d>',
		function()
			print(c)
			c = c + 1
			-- HYDRAS_OBJS[name]:exit()
			HYDRAS_OBJS[name]:activate()
		end,
		desc = 'Multi cursor: add selection for current word (equivalent to Ctrl-D in VSCode/Sublime)',
		mode = { 'n', 'x' },
	},
	{
		'<C-Down>',
		function()
			print(c)
			c = c + 1
			-- HYDRAS_OBJS[name]:exit()
			HYDRAS_OBJS[name]:activate()
		end,
		desc = 'Multi cusror: add below',
	},
	{
		'<C-Up>',
		function()
			print(c)
			c = c + 1
			-- HYDRAS_OBJS[name]:exit()
			HYDRAS_OBJS[name]:activate()
		end,
		desc = 'Multi cusror: add above',
	},
}

table.insert(M, {
	'mg979/vim-visual-multi',
	-- keys = bodies,
	init = function()
		-- TODO: create an hydra for it
		-- 		vim.cmd([[
		-- let g:VM_maps = {}
		-- let g:VM_maps['Find Under']         = '<M-d>'
		-- let g:VM_maps['Find Subword Under'] = '<M-d>'
		-- " let g:VM_maps['Add Cursor At Pos'] = '<M-D>'
		-- let g:VM_maps['Add Cursor Down'] = '<C-Down>'
		-- let g:VM_maps['Add Cursor Up'] = '<C-Up>'
		-- ]])

		vim.g.VM_default_mappings = 0
		vim.g.VM_highlight_matches = 'hi! link Search LspReferenceWrite' -- Non selected matches
		vim.g.VM_Mono_hl = 'TabLine' -- Cursor while in normal
		vim.g.VM_Extend_hl = 'TabLineSel' -- In Selection (NotUsed)
		vim.g.VM_Cursor_hl = 'TabLineSel' -- Cursor while in alt+d
		vim.g.VM_Insert_hl = 'TabLineSel' -- Cursor in insert
	end,
})

vim.api.nvim_create_autocmd('User', {
	pattern = 'visual_multi_exit',
	callback = function()
		-- HYDRAS_OBJS[name]:exit()
		-- Need to remap keys becuase vim-visual-multi overrides them
		vim.fn.timer_start(200, function()
			HYDRAS_OBJS[name]:exit()
		end)
	end,
})

HYDRAS[name] = {
	hint = [[
  _<M-x>_: Add Cursor for Current Word
  _<M-n>_: Next _<M-p>_: prev
	]],
	config = {
		color = 'pink',
		invoke_on_body = true,
		hint = {
			position = 'bottom',
			border = 'single',
			-- offset = 10,
		},
		on_exit = function()
			print('exitt')
		end,
	},
	mode = 'n',
	custom_bodies = bodies,
	heads = {
		{ '<M-x>', '<Plug>(VM-Find-Under)' },
		{
			'<M-n>',
			function()
				vim.call('vm#commands#find_next', 0, 1)
			end,
		},
		{
			'<M-p>',
			function()
				vim.call('vm#commands#find_prev', 0, 1)
			end,
		},
		-- stylua: ignore
		{ '<Esc>', '<Esc>', { exit = true } },
		-- {
		-- 	'<M-n>',
		-- 	function()
		-- 		print('up')
		-- 		vim.call('vm#commands#add_cursor_down', 0, 1)
		-- 	end,
		-- },
	},
}

return M
