local M = {}

local function is_entry_not_cword(entry, ctx)
	local word = entry:get_word()
	return word ~= string.sub(ctx.cursor_before_line, -#word, ctx.cursor.col - 1)
end

local function all_visible_buffers_source(priority, max_item_count)
	return {
		name = 'buffer',
		priority = priority,
		option = {
			get_bufnrs = function()
				local bufs = {}
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					bufs[vim.api.nvim_win_get_buf(win)] = true
				end
				return vim.tbl_keys(bufs)
			end,
		},
		max_item_count = max_item_count,
		-- entry_filter = is_entry_not_cword,
	}
end

-- Auto complete engine
table.insert(M, {
	'hrsh7th/nvim-cmp',
	enabled = false,
	version = false, -- last release is way too old
	event = { 'InsertEnter', 'CmdLineEnter' },
	dependencies = {
		'hrsh7th/cmp-nvim-lsp',
		'hrsh7th/cmp-buffer',
		'hrsh7th/cmp-path',
		'hrsh7th/cmp-cmdline',
		'dcampos/nvim-snippy',
		'dcampos/cmp-snippy',
		'ofirgall/cmp-lspkind-priority',
		'onsails/lspkind.nvim',
		'windwp/nvim-autopairs',
		'octaltree/cmp-look', -- TODO: maybe replace with https://github.com/uga-rosa/cmp-dictionary to support non linux users
		'hrsh7th/cmp-calc',
	},
	config = function(_, opts)
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

		local snippy = require('snippy')
		local cmp = require('cmp')
		cmp.setup({
			snippet = {
				expand = function(args)
					require('snippy').expand_snippet(args.body) -- For `snippy` users.
				end,
			},
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
				-- ['<Esc>'] = cmp.mapping(function (fallback)
				-- 	-- if cmp.visible() and snippy.can_jump(1) then
				-- 	if snippy.can_jump(1) then
				-- 		snippy.next()
				-- 	end
				-- 	fallback()
				-- end, { 'i' }),
				['<Tab>'] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					elseif snippy.can_jump(1) then
						snippy.next()
					else
						fallback()
					end
				end, { 'i', 'c' }),
				['<S-Tab>'] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif snippy.can_jump(-1) then
						snippy.previous()
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
				{ name = 'path', option = { trailing_slash = true }, priority = 500 },
				{ name = 'snippy', priority = 200 },
				-- { name = 'buffer', priority = 100, max_item_count = 5 },
				all_visible_buffers_source(150, 10),
				{
					name = 'look',
					priority = 50,
					max_item_count = 5,
					keyword_length = 3,
					option = { convert_case = true, loud = true },
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
		cmp.setup.cmdline('/', {
			sources = {
				all_visible_buffers_source(nil, 15),
			},
		})

		cmp.setup.cmdline(':', {
			sources = cmp.config.sources({
				{ name = 'path', option = { trailing_slash = true } },
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
table.insert(M, { 'hrsh7th/cmp-nvim-lsp', lazy = true, enabled = false })

table.insert(M, {
	"saghen/blink.cmp",
	lazy = false, -- lazy loading handled internally
	dependencies = { "rafamadriz/friendly-snippets" },
	version = "*",
	opts = {
		appearance = {
			use_nvim_cmp_as_default = false,
		},
		keymap = {
			["<CR>"] = { "accept", "fallback" },
			["<Tab>"] = {
				function(cmp)
					if cmp.snippet_active() then
						return cmp.accept()
					else
						return cmp.select_next()
					end
				end,
				"snippet_forward",
				"fallback",
			},
			["<S-Tab>"] = {
				function(cmp)
					if cmp.snippet_active() then
						return cmp.accept()
					else
						return cmp.select_prev()
					end
				end,
				"snippet_backward",
				"fallback",
			},
			["<Down>"] = { "select_next" },
			["<Up>"] = { "select_prev" },
		},
		completion = {
			list = {
				selection = "manual",
			},
			documentation = {
				auto_show = true,
			},
			menu = {
				draw = {
					columns = { { "kind_icon" }, { "label" } },
				},
			},
		},
	},
	config = function(_, opts)
		opts.appearance.kind_icons = require("ofirkai.plugins.nvim-cmp").kind_icons

		require("blink-cmp").setup(opts)
	end,
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

-- Snippet engine
table.insert(M, {
	'dcampos/nvim-snippy',
	dependencies = {
		'ofirgall/vim-snippets',
	},
	event = 'InsertEnter',
	opts = {
		mappings = {
			s = {
				['<Tab>'] = 'next',
				['<S-Tab>'] = 'previous',
			},
			nx = {
				['<Tab>'] = 'next',
				['<S-Tab>'] = 'previous',
			},
		},
	},
})

-- Autopair
table.insert(M, {
	'windwp/nvim-autopairs',
	event = 'InsertEnter',
	opts = {
		check_ts = true,
		disable_filetype = { 'TelescopePrompt', 'guihua', 'guihua_rust', 'clap_input' },
	},
})

-- Cargo.toml cmp sources
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
