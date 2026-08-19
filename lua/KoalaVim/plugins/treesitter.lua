local M = {}

-- Treesitter parser manager — syntax, folds, indent powered by TS grammars
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
	config = function(_, _)
		local available_langs = require('nvim-treesitter').get_available()

		local usercmd = require('KoalaVim.utils.cmd')
		vim.treesitter.language.register('markdown', 'sidekick_koala_prompt')

		-- Must target bufid explicitly — the filetype-changed buffer is often
		-- not current (e.g. picker preview), so bare vim.wo/vim.bo would
		-- clobber the wrong window.
		local function _apply_fold_indent(bufid)
			if vim.bo[bufid].buftype ~= '' then
				return
			end

			-- indentation, provided by nvim-treesitter
			vim.bo[bufid].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

			-- folds, provided by Neovim — window-local, so set per window.
			for _, win in ipairs(vim.fn.win_findbuf(bufid)) do
				vim.wo[win].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
				vim.wo[win].foldmethod = 'expr'
			end
		end

		local function _setup_ts(bufid, lang)
			-- syntax highlighting, provided by Neovim
			if not pcall(vim.treesitter.start, bufid, lang) then
				return
			end
			_apply_fold_indent(bufid)
		end

		local function _enable_ts(ft, bufid)
			local lang = vim.treesitter.language.get_lang(ft)
			if not vim.tbl_contains(available_langs, lang) then
				return
			end

			-- Re-check ts_highlight (not a one-way latch) — pickers reuse
			-- preview buffers and call vim.treesitter.stop() between results.
			if vim.b[bufid].ts_highlight then
				local active = vim.treesitter.highlighter.active[bufid]
				if active and active.tree and active.tree:lang() == lang then
					_apply_fold_indent(bufid)
					return
				end
				-- Different language — detach first to avoid leaking callbacks.
				vim.treesitter.stop(bufid)
			end

			-- Probe directly — install() rescans the full parser table (~640us),
			-- too expensive per preview keystroke.
			local probed, has_parser = pcall(vim.treesitter.language.add, lang)
			if probed and has_parser then
				_setup_ts(bufid, lang)
				return
			end

			-- install if not exist
			require('nvim-treesitter').install(lang):await(function()
				if not vim.api.nvim_buf_is_valid(bufid) then
					return
				end
				if vim.treesitter.language.get_lang(vim.bo[bufid].ft) ~= lang then
					return
				end
				_setup_ts(bufid, lang)
			end)
		end

		usercmd.create('TSKoala', 'Tree sitter enable via koala', function()
			_enable_ts(vim.bo.ft, vim.api.nvim_get_current_buf())
		end, {})

		vim.api.nvim_create_autocmd('FileType', {
			group = vim.api.nvim_create_augroup('lazy_treesitter', { clear = true }),
			callback = function(ev)
				_enable_ts(ev.match, ev.buf)
			end,
		})
	end,
})

-- Treesitter-powered text-objects: @function, @class, @block, @call, ...
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
			end, 'Select ' .. obj)
		end
	end,
})

-- Sticky header showing the enclosing function/class/block as you scroll
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

-- Context-aware commentstring (e.g. JSX inside TSX) for Comment.nvim
table.insert(M, {
	'JoosepAlviste/nvim-ts-context-commentstring',
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
	opts = {
		enable_autocmd = false,
		-- config = {
		-- 	query = '; %s',
		-- }
	},
	config = function(_, opts)
		require('ts_context_commentstring').setup(opts)
	end,
})

-- Show/yank JSONPath to the node under cursor in .json files
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

-- Enhanced % matching for language constructs (if/end, open/close tags)
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

-- Auto-insert matching `end` for blocks in Ruby/Lua/Bash/etc.
table.insert(M, {
	'RRethy/nvim-treesitter-endwise',
	dependencies = {
		'nvim-treesitter/nvim-treesitter',
	},
})

return M
