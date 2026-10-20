local M = {}

local function is_entry_not_cword(entry, ctx)
	local word = entry:get_word()
	return word ~= string.sub(ctx.cursor_before_line, -#word, ctx.cursor.col - 1)
end

local function all_visible_buffers_source(priority, max_item_count)
	return {
		name = 'fuzzy_buffer',
		priority = priority,
		option = {
			fuzzy_backend = 'fzy',
			get_bufnrs = function()
				local bufs = {}
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_config(win).relative == '' then
						bufs[vim.api.nvim_win_get_buf(win)] = true
					end
				end
				return vim.tbl_keys(bufs)
			end,
		},
		max_item_count = max_item_count,
		-- entry_filter = is_entry_not_cword,
	}
end

-- Auto complete engine, on top of LazyVim's nvim-cmp extra (`vim.g.lazyvim_cmp = 'nvim-cmp'`).
-- KoalaVim replaces the extra's sources/mappings/sorting/formatting and keeps its snippet setup,
-- auto brackets and snippet preview (`lazyvim.util.cmp`).
table.insert(M, {
	'hrsh7th/nvim-cmp',
	version = false, -- last release is way too old
	event = { 'InsertEnter', 'CmdlineEnter' },
	dependencies = {
		'hrsh7th/cmp-nvim-lsp',
		'KoalaVim/cmp-fuzzy-buffer',
		'KoalaVim/cmp-fuzzy-path',
		'hrsh7th/cmp-cmdline',
		'ofirgall/cmp-lspkind-priority',
		'onsails/lspkind.nvim',
		'windwp/nvim-autopairs',
		'KoalaVim/cmp-fuzzy-dictionary',
		'KoalaVim/cmp-agents-skills',
		'hrsh7th/cmp-calc',
		'not-manu/filemention.nvim',
	},
	opts = function(_, opts)
		-- onsails/lspkind-nvim
		local lspkind = require('lspkind')

		-- ofirgall/cmp-lspkind-priority
		local compare = require('cmp.config.compare')
		local lspkind_priority = require('cmp-lspkind-priority')
		lspkind_priority.setup({
			priority = {
				'Module',
				'Variable',
				'Field',
				'Keyword',
				'Snippet',

				'Method',
				'Function',
				'Constructor',
				'Class',
				'Interface',
				'Property',
				'Unit',
				'Value',
				'Enum',
				'Color',
				'File',
				'Reference',
				'Folder',
				'EnumMember',
				'Constant',
				'Struct',
				'Event',
				'Operator',
				'TypeParameter',
				'Text',
			},
		})

		local cmp = require('cmp')

		-- `snippet` (native `vim.snippet` + nvim-snippets) is kept from LazyVim's extra.
		-- KoalaVim's nvim-autopairs adds brackets on confirm, don't let LazyVim add them too.
		opts.auto_brackets = {}
		opts.completion = { completeopt = 'menu,menuone,noinsert,noselect' }

		return vim.tbl_extend('force', opts, {
			mapping = {
				['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-8), { 'i', 'c' }),
				['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(8), { 'i', 'c' }),
				['<C-y>'] = cmp.mapping(cmp.mapping.scroll_docs(-1), { 'i', 'c' }),
				['<C-e>'] = cmp.mapping(cmp.mapping.scroll_docs(1), { 'i', 'c' }),
				['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
				['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
				['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
				['<CR>'] = cmp.mapping(function(fallback)
					if cmp.visible() and cmp.get_selected_entry() ~= nil then
						cmp.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert })
					else
						fallback()
					end
				end, { 'i' }),
				-- Menu item, then snippet placeholder, then AI suggestion (LazyVim's actions)
				['<Tab>'] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					else
						LazyVim.cmp.map({ 'snippet_forward', 'ai_nes', 'ai_accept' }, fallback)()
					end
				end, { 'i', 'c' }),
				['<S-Tab>'] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif vim.snippet.active({ direction = -1 }) then
						vim.snippet.jump(-1)
					else
						fallback()
					end
				end, { 'i', 'c' }),
			},
			formatting = {
				format = lspkind.cmp_format({
					symbol_map = require('ofirkai.plugins.nvim-cmp').kind_icons,
					maxwidth = 50,
					mode = 'symbol',
				}),
			},
			window = require('ofirkai.plugins.nvim-cmp').window,
			sources = cmp.config.sources({
				{
					-- source for layzdev.nvim require statements and module annotations
					name = 'lazydev',
					group_index = 0, -- set group index to 0 to skip loading LuaLS completions
				},
				{
					name = 'nvim_lsp',
					priority = 1000,
					max_item_count = opts.lsp_max_item_count or 10,
					entry_filter = function(entry, ctx)
						-- Don't try to complete keywords or text when the user already typed the content
						local type = require('cmp.types').lsp.CompletionItemKind[entry:get_kind()]
						if type == 'Keyword' or type == 'Text' then
							return is_entry_not_cword(entry, ctx)
						end

						return true
					end,
				},
				{ name = 'filemention', priority = 600 },
				{ name = 'fuzzy_path', option = { trailing_slash = true, fuzzy_backend = 'zf' }, priority = 500 },
				{ name = 'agents_skills', priority = 300, option = { fuzzy_backend = 'fzf' } },
				{ name = 'snippets', priority = 200 },
				all_visible_buffers_source(150, 10),
				{
					name = 'fuzzy_dictionary',
					priority = 50,
					max_item_count = 7,
					keyword_length = 2,
				},
				{ name = 'calc', priority = 50 },
			}),
			-- performance = {
			-- 	debounce = 30, -- default: 60
			-- 	throttle = 15, -- default: 30
			-- },
			sorting = {
				comparators = {
					lspkind_priority.compare, -- compare.kind,
					require('cmp_fuzzy_buffer.compare'),
					compare.offset,
					compare.exact,
					-- compare.scopes,
					compare.score,
					compare.recently_used,
					compare.locality,
					compare.sort_text,
					compare.length,
					compare.order,
				},
			},
			preselect = cmp.PreselectMode.None, -- Auto select the first item
			experimental = {
				ghost_text = false,
			},
		})
	end,
	config = function(_, opts)
		-- Snippet parse fallback, auto brackets and missing snippet docs
		require('lazyvim.util.cmp').setup(opts)

		local cmp = require('cmp')
		cmp.setup.cmdline('/', {
			sources = {
				all_visible_buffers_source(nil, 15),
			},
		})

		cmp.setup.cmdline(':', {
			sources = cmp.config.sources({
				{ name = 'fuzzy_path', option = { trailing_slash = true, fuzzy_backend = 'zf' } },
			}, {
				{
					name = 'cmdline',
					option = {
						ignore_cmds = { 'Man', '!' },
					},
				},
			}),
		})

		-- ray-x/navigator.lua, No filetypes for guihua
		cmp.setup.filetype('guihua', {})
		cmp.setup.filetype('guihua_rust', {})

		local on_confirm_done_callback = function()
			require('nvim-autopairs.completion.cmp').on_confirm_done({ map_char = { tex = '' } })
		end

		cmp.event:on('confirm_done', on_confirm_done_callback)
	end,
})

-- Lazy load cmp_nvim_lsp for capabilities
table.insert(M, { 'hrsh7th/cmp-nvim-lsp', lazy = true })

-- Shared dependency for cmp-fuzzy-buffer, cmp-fuzzy-path, and cmp-fuzzy-dictionary
table.insert(M, {
	'KoalaVim/fuzzy.nvim',
	lazy = true,
	dependencies = {
		{ 'romgrk/fzy-lua-native', build = 'make' },
		{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
		{ 'natecraddock/telescope-zf-native.nvim' },
	},
})

-- Fuzzy matching cmp source for buffer words
table.insert(M, { 'KoalaVim/cmp-fuzzy-buffer', dependencies = { 'KoalaVim/fuzzy.nvim' }, lazy = true })

-- Fuzzy matching cmp source for filesystem paths
table.insert(M, { 'KoalaVim/cmp-fuzzy-path', dependencies = { 'KoalaVim/fuzzy.nvim' }, lazy = true })

-- Fuzzy dictionary cmp source
table.insert(M, {
	'KoalaVim/cmp-fuzzy-dictionary',
	lazy = true,
	dependencies = { 'KoalaVim/fuzzy.nvim' },
	config = function()
		require('cmp_fuzzy_dictionary').reload({
			paths = { '/usr/share/dict/words' },
			fuzzy_backend = 'fzf',
		})
	end,
})

-- Agent skills cmp source
table.insert(M, {
	'KoalaVim/cmp-agents-skills',
	lazy = true,
	dependencies = { 'KoalaVim/fuzzy.nvim' },
})

-- Mention and complete file paths in insert mode
table.insert(M, {
	'not-manu/filemention.nvim',
	event = 'InsertEnter',
	dependencies = { 'dmtrKovalenko/fff.nvim' },
	opts = {
		filetypes = { 'markdown', 'text', 'gitcommit', 'sidekick_koala_prompt' },
		finder = 'fff',
	},
})

-- Github cmp source
table.insert(M, {
	'petertriho/cmp-git',
	ft = 'gitcommit',
	dependencies = {
		'hrsh7th/nvim-cmp',
	},
	config = function()
		require('cmp_git').setup()

		require('cmp').setup.filetype('dap-repl', {
			sources = {
				{ name = 'dap' },
			},
		})

		require('cmp').setup.filetype('dapui_watches', {
			sources = {
				all_visible_buffers_source(150, 15),
				{ name = 'dap' },
			},
		})
	end,
})

-- VSCode-format snippets for the native `vim.snippet` engine (from LazyVim's nvim-cmp extra, with friendly-snippets).
-- Adds KoalaVim's own snippets (`snippets/package.json`) next to the user's `<config>/snippets`.
table.insert(M, {
	'garymjr/nvim-snippets',
	opts = function(_, opts)
		local koala_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h:h:h')
		opts.search_paths = opts.search_paths or { vim.fn.stdpath('config') .. '/snippets' }
		table.insert(opts.search_paths, koala_root .. '/snippets')
	end,
})

-- Auto-insert matching pairs (brackets, quotes) with treesitter awareness
table.insert(M, {
	'windwp/nvim-autopairs',
	event = 'InsertEnter',
	opts = {
		check_ts = true,
		disable_filetype = { 'snacks_picker_input', 'guihua', 'guihua_rust', 'clap_input' },
	},
})

-- Cargo.toml completion, version info, and management for Rust crates
table.insert(M, {
	'saecki/crates.nvim',
	ft = 'toml',
	dependencies = {
		'hrsh7th/nvim-cmp',
	},
	config = function()
		require('crates').setup()

		require('cmp').setup.filetype('toml', {
			sources = {
				{ name = 'crates', priority = 500 },
				all_visible_buffers_source(nil, 15),
			},
		})
	end,
})

return M
