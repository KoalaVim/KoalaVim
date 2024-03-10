local M = {}
-- Plugins you interact by actual coding

local usercmd = require('KoalaVim.utils.cmd')

table.insert(M, {
	'numToStr/Comment.nvim',
	event = { 'BufReadPre', 'BufNewFile' },
	config = function(_, opts)
		if opts.pre_hook == nil then
			-- TODO: check it would work after fixing #16
			opts.pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
		end
		require('Comment').setup(opts)
	end,
	dependencies = {
		'JoosepAlviste/nvim-ts-context-commentstring',
	},
})

table.insert(M, {
	'gbprod/substitute.nvim',
	keys = {
		{
			'cx',
			function()
				require('substitute.exchange').operator()
			end,
			desc = 'Operator: substitute/exchange',
		},
		{
			'cxx',
			function()
				require('substitute.exchange').line()
			end,
			desc = 'Operator: substitute/exchange line',
		},
		{
			'cx',
			function()
				require('substitute.exchange').visual()
			end,
			desc = 'Operator: substitute/exchange',
			mode = 'x',
		},
	},
	config = function(_, opts)
		require('substitute').setup(opts)
	end,
})

table.insert(M, {
	'windwp/nvim-autopairs',
	event = { 'InsertEnter' },
	opts = {
		check_ts = true,
		disable_filetype = { 'TelescopePrompt', 'guihua', 'guihua_rust', 'clap_input' },
		-- enable_moveright = false,
	},
	config = function(_, opts)
		require('nvim-autopairs').setup(opts)
	end,
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
})

table.insert(M, {
	'nacro90/numb.nvim',
	event = 'CmdLineEnter',
	opts = {
		number_only = true,
	},
	config = function(_, opts)
		require('numb').setup(opts)
	end,
})

table.insert(M, {
	'ggandor/leap.nvim',
	opts = {
		max_aot_targets = nil,
		highlight_unlabeled = false,
	},
	config = function(_, opts)
		require('leap').setup(opts)
	end,
	keys = {
		{ '<leader>s', '<Plug>(leap-forward)', mode = { 'n', 'x' }, desc = 'Leap forward' },
		{ '<leader>S', '<Plug>(leap-backward)', mode = { 'n', 'x' }, desc = 'Leap backard' },
	},
})

table.insert(M, {
	'ggandor/flit.nvim',
	dependencies = {
		'ggandor/leap.nvim',
	},
	opts = {
		labeled_modes = 'nv',
	},
	config = function(_, opts)
		require('flit').setup(opts)
	end,
	keys = { 'f', 'F', 't', 'T' },
})

table.insert(M, {
	'andrewferrier/debugprint.nvim',
	opts = {
		print_tag = '--- DEBUG PRINT ---',
	},
	config = function(_, opts)
		require('debugprint').setup(opts)
	end,
	keys = { 'g?p', 'g?P', 'g?v', 'g?V' },
	cmd = 'DeleteDebugPrints',
})

table.insert(M, {
	'nguyenvukhang/nvim-toggler',
	opts = {
		inverses = {
			['to'] = 'from',
			['failed'] = 'succeeded',
			['before'] = 'after',
			['prev'] = 'next',
			['above'] = 'below',
			['start'] = 'end',
		},
		remove_default_keybinds = true,
	},
	config = function(_, opts)
		require('nvim-toggler').setup(opts)
	end,
	keys = {
		{
			'<leader>i',
			function()
				require('nvim-toggler').toggle()
			end,
			mode = { 'n', 'v' },
			desc = 'Invert words',
		},
	},
})

local text_case_cmd_table = {
	['UpperCase'] = 'to_upper_case',
	['LowerCase'] = 'to_lower_case',
	['SnakeCase'] = 'to_snake_case',
	['ConstantCase'] = 'to_dash_case',
	['DashCase'] = 'to_constant_case',
	['DotCase'] = 'to_dot_case',
	['CamelCase'] = 'to_camel_case',
	['PascalCase'] = 'to_pascal_case',
	['TitleCase'] = 'to_title_case',
	['PathCase'] = 'to_path_case',
	['PhraseCase'] = 'to_phrase_case',
}

local text_case_cmds = {}

for key, _ in pairs(text_case_cmd_table) do
	table.insert(text_case_cmds, key)
end

table.insert(M, {
	'johmsalas/text-case.nvim',
	cmd = text_case_cmds,
	config = function(_, opts)
		local textcase = require('textcase')
		textcase.setup(opts)

		for usrcmd, apiname in pairs(text_case_cmd_table) do
			usercmd.create(usrcmd, 'Convert case to ' .. usrcmd, function()
				textcase.current_word(apiname)
			end, {})
		end
	end,
})

table.insert(M, {
	'gbprod/yanky.nvim',
	opts = {
		system_clipboard = {
			sync_with_ring = false,
		},
		highlight = {
			on_put = false,
			on_yank = false,
		},
	},
	config = function(_, opts)
		require('yanky').setup(opts)
	end,
	keys = {
		{ 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank with yanky.nvim' },
		{ 'p', '<Plug>(YankyPutAfter)', desc = 'Paste with yanky.nvim' },
		{ 'P', '<Plug>(YankyPutBefore)', desc = 'Paste with yank.nvim' },
		{ 'p', '"_d<Plug>(YankyPutBefore)', mode = 'x', desc = 'replace text without changing the copy register' },
		{ 'P', '"_d<Plug>(YankyPutAfter)', mode = 'x', desc = 'replace text without changing the copy register' },
		{ '<M-[>', '<Plug>(YankyCycleForward)', desc = 'Cycle yank history forward' },
		{ '<M-]>', '<Plug>(YankyCycleBackward)', desc = 'Cycle yank history backward' },
	},
})

table.insert(M, {
	'kylechui/nvim-surround',
	keys = {
		{ 'sa', desc = 'Add surround' },
		{ 's', mode = 'v', desc = 'Add surround' },
		{ 'S', mode = 'v', desc = 'Add surround for a line' },
		{ 'sd', desc = 'Delete surround' },
		{ 'sr', desc = 'Replace surround' },

		--Surround word
		{ 'sw', 'saiw', desc = 'Surround word', remap = true },
		{ 'sW', 'saiW', desc = 'Surround WORD', remap = true },

		-- Brackets
		{ '<leader>(', 'srB(', desc = 'Replace surround to (', remap = true },
		{ '<leader>{', 'srB{', desc = 'Replace surround to {', remap = true },
		{ '<leader>[', 'srB[', desc = 'Replace surround to [', remap = true },

		-- strings
		{ "<leader>'", "srq'", desc = "Replace surround to '", remap = true },
		{ '<leader>"', 'srq"', desc = 'Replace surround to "', remap = true },
		{ '<leader>`', 'srq`', desc = 'Replace surround to `', remap = true },
	},
	config = function()
		-- switch the surround direction behavior
		local surrounds = require('nvim-surround.config').default_opts.surrounds
		local switched_surrounds = {
			{ '{', '}' },
			{ '(', ')' },
			{ '[', ']' },
			{ '<', '>' },
		}
		for _, pair in ipairs(switched_surrounds) do
			local tmp = surrounds[pair[1]]
			surrounds[pair[1]] = surrounds[pair[2]]
			surrounds[pair[2]] = tmp
		end

		require('nvim-surround').setup({
			keymaps = {
				normal = 'sa',
				normal_cur = false,
				normal_line = false,
				normal_cur_line = false,
				visual = 's',
				visual_line = 'S',
				delete = 'sd',
				change = 'sr',
			},
			aliases = {
				['i'] = '[', -- Index
				['r'] = '(', -- Round
				['b'] = '{', -- Brackets
				['B'] = { '{', '(', '[' },
			},
			surrounds = surrounds,
			move_cursor = false,
		})
	end,
})

table.insert(M, {
	'Wansmer/treesj',
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	opts = {
		use_default_keymaps = false,
	},
	config = function(_, opts)
		require('treesj').setup(opts)
	end,
	keys = {
		{ 'sj', '<cmd>TSJSplit<cr>', desc = 'Splitjoin Split line' },
		{ 'sJ', '<cmd>TSJJoin<cr>', desc = 'Splitjoin Join line' },
	},
})

table.insert(M, {
	'Wansmer/sibling-swap.nvim',
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	opts = {
		use_default_keymaps = false,
	},
	config = function(_, opts)
		require('sibling-swap').setup(opts)
	end,
	keys = {
		{
			'<C-Right>',
			function()
				require('sibling-swap').swap_with_right()
			end,
		},
		{
			'<C-Left>',
			function()
				require('sibling-swap').swap_with_left()
			end,
		},
		{
			'<space><Right>',
			function()
				require('sibling-swap').swap_with_right_with_opp()
			end,
		},
		{
			'<space><Left>',
			function()
				require('sibling-swap').swap_with_left_with_opp()
			end,
		},
	},
})

table.insert(M, {
	'chrisgrieser/nvim-various-textobjs',
	opts = {
		useDefaultKeymaps = true,
		disabledKeymaps = { '%' },
	},
	config = function(_, opts)
		require('various-textobjs').setup(opts)
		local map = require('KoalaVim.utils.map').map
		-- stylua: ignore start
		map({ 'o', 'x' }, 'is', function() require('various-textobjs').subword(true) end)
		map({ 'o', 'x' }, 'as', function() require('various-textobjs').subword(false) end)
		map({ 'o', 'x' }, 'i|', function() require('various-textobjs').shellPipe(true) end)
		map({ 'o', 'x' }, 'a|', function() require('various-textobjs').shellPipe(false) end)
		-- stylua: ignore end
	end,
})

table.insert(M, {
	'echasnovski/mini.ai',
	config = function(_, opts)
		require('mini.ai').setup(opts)
	end,
})

table.insert(M, {
	'mg979/vim-visual-multi',
	keys = {
		{
			'<M-d>',
			desc = 'Multi cursor: add selection for current word (equivalent to Ctrl-D in VSCode/Sublime)',
			mode = { 'n', 'x' },
		},
		{ '<C-Down>', desc = 'Multi cusror: add below' },
		{ '<C-Up>', desc = 'Multi cusror: add above' },
	},
	init = function()
		-- TODO: create an hydra for it
		vim.cmd([[
let g:VM_maps = {}
let g:VM_maps['Find Under']         = '<M-d>'
let g:VM_maps['Find Subword Under'] = '<M-d>'
let g:VM_maps['Add Cursor Down'] = '<C-Down>'
let g:VM_maps['Add Cursor Up'] = '<C-Up>'
]])

		vim.g.VM_highlight_matches = 'hi! link Search LspReferenceWrite' -- Non selected matches
		vim.g.VM_Mono_hl = 'TabLine' -- Cursor while in normal
		vim.g.VM_Extend_hl = 'TabLineSel' -- In Selection (NotUsed)
		vim.g.VM_Cursor_hl = 'TabLineSel' -- Cursor while in alt+d
		vim.g.VM_Insert_hl = 'TabLineSel' -- Cursor in insert
	end,
})

-- TODO: dial.nvim doesn't work for some reason
-- table.insert(M, {
-- 	-- Enhance C-X/A
-- 	'monaqa/dial.nvim',
-- 	keys = {
-- 		{ '<C-a>', function() require('dial.map').inc_normal() end, expr = true },
-- 		{ '<C-x>', function() require('dial.map').dec_normal() end },
-- 		{ '<C-a>', function() require('dial.map').inc_visual() end, mode = 'v' },
-- 		{ '<C-x>', function() require('dial.map').dec_visual() end, mode = 'v' },
-- 		{ 'g<C-a>', function() require('dial.map').inc_gvisual() end, mode = 'v' },
-- 		{ 'g<C-x>', function() require('dial.map').dec_gvisual() end, mode = 'v' },
-- 	},
-- 	config = function()
-- 		local augend = require('dial.augend')
-- 		require('dial.config').augends:register_group({
-- 			default = {
-- 				augend.integer.alias.decimal,
-- 				augend.integer.alias.hex,
-- 				augend.date.alias['%Y/%m/%d'],
-- 				augend.constant.alias.bool,
-- 				augend.semver.alias.semver,
-- 			},
-- 		})
-- 	end,
-- })

table.insert(M, {
	'fedepujol/move.nvim',
	keys = {
		{ '<C-k>', ':MoveBlock(-1)<CR>', mode = 'v', silent = true },
		{ '<C-j>', ':MoveBlock(1)<CR>', mode = 'v', silent = true },
		{ '<C-l>', ':MoveHBlock(1)<CR>', mode = 'v', silent = true },
		{ '<C-h>', ':MoveHBlock(-1)<CR>', mode = 'v', silent = true },
	},
})

return M
