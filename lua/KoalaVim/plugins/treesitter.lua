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
	---@type TSConfig
	opts = {
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
		-- nvim-treesitter/nvim-treesitter-textobjects
		textobjects = {
			move = {
				enable = true,
				set_jumps = true, -- whether to set jumps in the jumplist
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
		rainbow = {
			enable = true,
		}
	},
	---@param opts TSConfig
	config = function(_, opts)
		require('nvim-treesitter').setup(opts)
	end,
})

table.insert(M, {
	'nvim-treesitter/nvim-treesitter-textobjects',
	branch = 'main', -- The future default branch
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
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

table.insert(M, {
	'JoosepAlviste/nvim-ts-context-commentstring',
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
})

table.insert(M, {
	'nvim-treesitter/playground',
	cmd = 'TSPlaygroundToggle',
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
})

table.insert(M, {
	'phelipetls/jsonpath.nvim',
	ft = { 'json', 'jsonc' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	config = function()
		require('jsonpath')
	end,
})

table.insert(M, {
	'andymass/vim-matchup',
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	init = function()
		-- Disable matchup higlights, use the default of vim
		vim.api.nvim_create_autocmd('FileType', {
			pattern = '*',
			callback = function()
				vim.b.matchup_matchparen_enabled = 0
			end,
		})
	end,
})

table.insert(M, {
	'RRethy/nvim-treesitter-endwise',
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
})


return M
