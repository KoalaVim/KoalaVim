local M = {}

local kkeys = require('KoalaVim.utils.map').kkeys
local koala_flavor = require('KoalaVim.flavor').get() == 'koala'

-- LazyVim's class jumps `]c` `[c` `]C` `[C` (it also owns the `]f`/`]a` ones): the koala flavor disables the first four,
-- they conflict with diff navigation and KoalaVim's git hunk/dirty-file keys. KoalaVim jumps classes with `]]`/`[[`.
-- The lazyvim flavor keeps LazyVim's keys (`false` = remove the key from the merged LazyVim opts).
local no_class_jump = nil
if koala_flavor then
	no_class_jump = false
end
local lazyvim_moves = {}
for _, key in ipairs({ 'f', 'c', 'a', 'F', 'C', 'A' }) do
	lazyvim_moves[']' .. key] = true
	lazyvim_moves['[' .. key] = true
end

-- Treesitter parser manager — syntax, folds, indent powered by TS grammars
-- The core spec (build, events, highlight/indent/folds features) comes from LazyVim, this adds
-- KoalaVim's parsers, incremental selection and on demand parsers install.
table.insert(M, {
	'nvim-treesitter/nvim-treesitter',
	-- Merged with LazyVim's list (`opts_extend`)
	opts = {
		ensure_installed = {
			'cmake',
			'cpp',
			'css',
			'dockerfile',
			'git_rebase',
			'gitcommit',
			'gitignore',
			'go',
			'gomod',
			'gosum',
			'make',
			'proto',
			'rust',
			'sql',
			'zig',
		},
	},
	keys = kkeys({
		-- Not `<CR>`: visual `<CR>` copies to the os clipboard
		{
			'<C-Space>',
			function()
				return require('KoalaVim.utils.ts_selection').start_expr()
			end,
			expr = true,
			desc = 'Select treesitter node',
		},
		{
			'<C-Space>',
			function()
				return require('KoalaVim.utils.ts_selection').expand_expr()
			end,
			expr = true,
			mode = 'x',
			desc = 'Increment selection',
		},
		{
			'<BS>',
			function()
				return require('KoalaVim.utils.ts_selection').shrink_expr()
			end,
			expr = true,
			mode = 'x',
			desc = 'Decrement selection',
		},
	}),
	init = function()
		local usercmd = require('KoalaVim.utils.cmd')
		vim.treesitter.language.register('markdown', 'sidekick_koala_prompt')

		local available_langs ---@type string[]?

		-- LazyVim's FileType hook sets highlight, indent and folds for installed parsers. A parser
		-- installed on demand shows up after that hook ran, so do the same here.
		-- Must target bufid explicitly — the filetype-changed buffer is often
		-- not current (e.g. picker preview), so bare vim.wo/vim.bo would
		-- clobber the wrong window.
		local function _start_ts(bufid, lang)
			if vim.bo[bufid].buftype ~= '' then
				return
			end

			-- syntax highlighting, provided by Neovim
			if not pcall(vim.treesitter.start, bufid, lang) then
				return
			end

			-- indentation, provided by nvim-treesitter
			vim.bo[bufid].indentexpr = 'v:lua.LazyVim.treesitter.indentexpr()'

			-- folds, provided by Neovim — window-local, so set per window.
			for _, win in ipairs(vim.fn.win_findbuf(bufid)) do
				vim.wo[win].foldexpr = 'v:lua.LazyVim.treesitter.foldexpr()'
				vim.wo[win].foldmethod = 'expr'
			end
		end

		---@param force boolean? start treesitter even if the parser is already installed
		local function _enable_ts(ft, bufid, force)
			local lang = vim.treesitter.language.get_lang(ft)
			if not lang then
				return
			end

			-- Probe directly — install() rescans the full parser table (~640us),
			-- too expensive per preview keystroke.
			local probed, has_parser = pcall(vim.treesitter.language.add, lang)
			if probed and has_parser then
				if force then
					vim.treesitter.stop(bufid)
					_start_ts(bufid, lang)
				end
				return
			end

			local has_ts, TS = pcall(require, 'nvim-treesitter')
			if not has_ts then
				return
			end
			available_langs = available_langs or TS.get_available()
			if not vim.tbl_contains(available_langs, lang) then
				return
			end

			-- install if not exist
			TS.install(lang):await(function()
				if not vim.api.nvim_buf_is_valid(bufid) then
					return
				end
				if vim.treesitter.language.get_lang(vim.bo[bufid].ft) ~= lang then
					return
				end
				LazyVim.treesitter.get_installed(true) -- refresh the installed langs
				_start_ts(bufid, lang)
			end)
		end

		usercmd.create('TSKoala', 'Tree sitter enable via koala', function()
			_enable_ts(vim.bo.ft, vim.api.nvim_get_current_buf(), true)
		end, {})

		vim.api.nvim_create_autocmd('FileType', {
			group = vim.api.nvim_create_augroup('koala_treesitter', { clear = true }),
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
					[']c'] = no_class_jump,
					[']f'] = '@function.outer',
					[']]'] = '@class.outer',
					[']b'] = '@block.outer',
					[']a'] = '@parameter.inner',
					[']k'] = '@call.outer',
				},
				goto_next_end = {
					[']C'] = no_class_jump,
					[']F'] = '@function.outer',
					[']B'] = '@block.outer',
					[']A'] = '@parameter.inner',
					[']K'] = '@call.outer',
				},
				goto_previous_start = {
					['[c'] = no_class_jump,
					['[f'] = '@function.outer',
					['[['] = '@class.outer',
					['[b'] = '@block.outer',
					['[a'] = '@parameter.inner',
					['[k'] = '@call.inner',
				},
				goto_previous_end = {
					['[C'] = no_class_jump,
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
				-- Function (`f`), class (`c`), block (`o`) and more are provided by mini.ai
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
				['ak'] = '@call.outer', -- same as the `]k` motions
				['ik'] = '@call.inner',
				['ai'] = '@conditional.outer', -- i as if
				['ii'] = '@conditional.inner',
				-- Custom captures
				['ix'] = '@binary_expression.inner', -- `ie` is mini.ai's case word
				['aF'] = '@function.name',
			},
		},
	},
	config = function(_, opts)
		-- Disable entire built-in ftplugin mappings to avoid conflicts.
		-- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
		vim.g.no_plugin_maps = true

		local map = require('KoalaVim.utils.map').kmap
		require('nvim-treesitter-textobjects').setup(opts)

		-- Set move cmds
		for goto_cmd, keys in pairs(opts.move.keys) do
			for lhs, obj in pairs(keys) do
				if obj then
					local rhs = function()
						-- Same as LazyVim's: `]c`/`[c` are diff jumps in diff windows
						if vim.wo.diff and lhs:find('[cC]') then
							return vim.cmd('normal! ' .. lhs)
						end
						require('nvim-treesitter-textobjects.move')[goto_cmd](obj, 'textobjects')
					end
					if not koala_flavor and lazyvim_moves[lhs] then
						-- LazyVim's own jumps, the contested table treats them as LazyVim's keys (same desc as LazyVim's)
						local desc = obj:gsub('@', ''):gsub('%..*', '')
						desc = desc:sub(1, 1):upper() .. desc:sub(2)
						desc = (lhs:sub(1, 1) == '[' and 'Prev ' or 'Next ') .. desc
						desc = desc .. (lhs:sub(2, 2) == lhs:sub(2, 2):upper() and ' End' or ' Start')
						require('KoalaVim.utils.map').map({ 'n', 'x', 'o' }, lhs, rhs, desc)
					else
						map({ 'n', 'x', 'o' }, lhs, rhs, goto_cmd .. ' ' .. obj)
					end
				end
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
