local M = {}

table.insert(M, {
	'nvim-treesitter/nvim-treesitter',
	version = false, -- last release is way too old
	lazy = false,
	build = ':TSUpdate',
	event = { 'BufReadPost', 'BufNewFile' },
	keys = {
		{ '<CR>', desc = 'Increment selection' },
		{ '<BS>', desc = 'Decrement selection', mode = 'x' },
	},
	opts_old = {
		-- TODO: configure ensure_installed by default not 'all'
		-- TODO: install treesitter on demand?
		ensure_installed = 'all',
		sync_install = false,
		-- TODO: configure ignore_install + doc why those are ignored
		ignore_install = { 'help', 'git_rebase', 'gitcommit', 'comment' },
		highlight = {
			enable = true,
		},
		indent = {
			enable = true,
		},
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = '<CR>',
				node_incremental = '<CR>',
				scope_incremental = '<S-CR>',
				node_decremental = '<BS>',
			},
		},
		-- yati = { enable = true },
		-- andymass/vim-matchup
		matchup = {
			enable = true,
		},
		-- mrjones2014/nvim-ts-rainbow
		rainbow = {
			enable = true,
			-- disable = { "jsx", "cpp" },
			extended_mode = false,
			max_file_lines = nil,
			colors = {
				-- '#ff3429',
				'#ff647e',
				'#ff57d5',
				'#ffd121',
				'#68dd6a',
				'#ff880e',
				'#41a2ac',
				'#26cca0',
			},
			-- colors = {}, -- table of hex strings
			-- termcolors = {} -- table of colour name strings
		},
		-- JoosepAlviste/nvim-ts-context-commentstring
		context_commentstring = {
			enable = true,
			enable_autocmd = false,
			config = {
				query = '; %s',
			},
		},
		-- RRethy/nvim-treesitter-endwise
		-- rainbow = {
		-- 	enable = true,
		-- }
	},
	config = function(_, _)
		local enabled = {}
		local available_langs = require('nvim-treesitter').get_available()

		local usercmd = require('KoalaVim.utils.cmd')
		local function _enable_ts(ft)
			if vim.tbl_contains(available_langs, ft) then
				enabled[ft] = true

				-- install if not exist
				require('nvim-treesitter').install(ft):await(function()
					-- syntax highlighting, provided by Neovim
					vim.treesitter.start()
					-- folds, provided by Neovim
					vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
					vim.wo.foldmethod = 'expr'
					-- indentation, provided by nvim-treesitter
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end)
			end
		end

		usercmd.create('TSKoala', 'Tree sitter enable via koala', function()
			_enable_ts(vim.bo.ft)
		end, {})

		vim.api.nvim_create_autocmd('FileType', {
			group = vim.api.nvim_create_augroup('lazy_treesitter', { clear = true }),
			callback = function(ev)
				if not enabled[ev.match] then
					_enable_ts(ev.match)
				end
			end,
		})
	end,
})

table.insert(M, {
	'nvim-treesitter/nvim-treesitter-textobjects',
	branch = 'main', -- The future default branch
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	opts = {
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			keys = {
				goto_next_start = {
					[']f'] = '@function.outer',
					[']]'] = '@class.outer',
					[']b'] = '@block.outer',
					[']a'] = '@parameter.inner',
					[']k'] = '@call.outer',
				},
				goto_next_end = {
					[']F'] = '@function.outer',
					[']B'] = '@block.outer',
					[']A'] = '@parameter.inner',
					[']K'] = '@call.outer',
				},
				goto_previous_start = {
					['[f'] = '@function.outer',
					['[['] = '@class.outer',
					['[b'] = '@block.outer',
					['[a'] = '@parameter.inner',
					['[k'] = '@call.inner',
				},
				goto_previous_end = {
					['[F'] = '@function.outer',
					['[B'] = '@block.outer',
					['[A'] = '@parameter.inner',
					['[K'] = '@call.inner',
				},
			},
		},
		select = {
			enable = true,
			lookahead = true,
			lookbehind = true,
			-- include_surrounding_whitespace = true,
			keymaps = {
				['af'] = '@function.outer',
				['if'] = '@function.inner',
				['aC'] = '@class.outer',
				['iC'] = '@class.inner',
				['ab'] = '@block.outer',
				['ib'] = '@block.inner',
				['aL'] = '@loop.outer', -- `al` is already in used by `a line`
				['iL'] = '@loop.inner', -- same as `al`
				['a/'] = '@comment.outer',
				['i/'] = '@comment.outer', -- no inner for comment
				-- Handled by `mini.ai`
				-- ['aa'] = '@parameter.outer', -- parameter -> argument
				-- ['ia'] = '@parameter.inner',
				['ac'] = '@call.outer',
				['ic'] = '@call.inner',
				['ai'] = '@conditional.outer', -- i as if
				['ii'] = '@conditional.inner',
				-- Custom captures
				['ie'] = '@binary_expression.inner',
				['aF'] = '@function.name',
			},
		},
	},
	config = function(_, opts)
		-- Disable entire built-in ftplugin mappings to avoid conflicts.
		-- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
		vim.g.no_plugin_maps = true

		local map = require('KoalaVim.utils.map').map
		require('nvim-treesitter-textobjects').setup(opts)

		-- Set move cmds
		for goto_cmd, keys in pairs(opts.move.keys) do
			for lhs, obj in pairs(keys) do
				map({ 'n', 'x', 'o' }, lhs, function()
					require('nvim-treesitter-textobjects.move')[goto_cmd](obj, 'textobjects')
				end, goto_cmd .. ' ' .. obj)
			end
		end

		-- Set select cmds
		for lhs, obj in pairs(opts.select.keymaps) do
			map({ 'x', 'o' }, lhs, function()
				require('nvim-treesitter-textobjects.select').select_textobject(obj, 'textobjects')
			end,  'Select ' .. obj)
		end
	end,
})

table.insert(M, {
	'nvim-treesitter/nvim-treesitter-context',
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	config = function(_, opts)
		require('treesitter-context').setup(opts)
	end,
})

-- table.insert(M, {
-- 	'JoosepAlviste/nvim-ts-context-commentstring',
-- 	event = { 'BufReadPre', 'BufNewFile' },
-- 	dependencies = {
-- 		'nvim-treesitter/nvim-treesitter',
-- 	},
-- })
--
-- table.insert(M, {
-- 	'nvim-treesitter/playground',
-- 	cmd = 'TSPlaygroundToggle',
-- 	dependencies = {
-- 		'nvim-treesitter/nvim-treesitter',
-- 	},
-- })
--
-- table.insert(M, {
-- 	'phelipetls/jsonpath.nvim',
-- 	ft = { 'json', 'jsonc' },
-- 	dependencies = {
-- 		'nvim-treesitter/nvim-treesitter',
-- 	},
-- 	config = function()
-- 		require('jsonpath')
-- 	end,
-- })
--
-- table.insert(M, {
-- 	'andymass/vim-matchup',
-- 	event = { 'BufReadPre', 'BufNewFile' },
-- 	dependencies = {
-- 		'nvim-treesitter/nvim-treesitter',
-- 	},
-- 	init = function()
-- 		-- Disable matchup higlights, use the default of vim
-- 		vim.api.nvim_create_autocmd('FileType', {
-- 			pattern = '*',
-- 			callback = function()
-- 				vim.b.matchup_matchparen_enabled = 0
-- 			end,
-- 		})
-- 	end,
-- })
--
-- table.insert(M, {
-- 	'RRethy/nvim-treesitter-endwise',
-- 	dependencies = {
-- 		'nvim-treesitter/nvim-treesitter',
-- 	},
-- })

return M
