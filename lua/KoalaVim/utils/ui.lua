local M = {}

M.lualine_opts = {}

local uv = vim.loop

local function get_current_lsp_server_name()
	local msg = 'n/a'
	local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
	local clients = vim.lsp.get_active_clients()
	if next(clients) == nil then
		return msg
	end
	for _, client in ipairs(clients) do
		local filetypes = client.config.filetypes
		if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
			return client.name
		end
	end
	return msg
end

local function gen_info_string(icon, desc, icons_only)
	if icons_only then
		return icon
	end

	if icon == nil then
		return desc
	end

	return icon .. ' ' .. desc
end

local function lsp_count_str(lsp_count, key)
	local workspace = lsp_count.workspace[key]
	local file = lsp_count.file[key]

	local ret = tostring(file)
	if workspace > file then
		ret = ret .. '(' .. tostring(workspace) .. ')'
	end

	return ret
end

LAST_LSP_COUNT = 0
LAST_LSP_COUNT_RES = ''

local function get_lsp_count()
	local now = uv.now()
	if now - LAST_LSP_COUNT < 800 then
		return LAST_LSP_COUNT_RES
	end
	LAST_LSP_COUNT = now

	local lsp_count = require('dr-lsp').lspCountTable()
	if lsp_count == nil then
		return ''
	end

	LAST_LSP_COUNT_RES = string.format(
		'𝘿 %s 𝙍 %s',
		lsp_count_str(lsp_count, 'definitions'),
		lsp_count_str(lsp_count, 'references')
	)
	return LAST_LSP_COUNT_RES
end

function M.setup_lualine(is_half, opts)
	if opts then
		M.lualine_opts = opts
	end

	local icons_only = require('KoalaVim').conf.ui.statusline.icons_only
	if is_half then
		icons_only = true
	end

	local info_seperator = ' │ '
	if icons_only then
		info_seperator = ' '
	end

	local y_section = {
		{
			function()
				return require('gitblame').get_current_blame_text()
			end,
			cond = function()
				return package.loaded['gitblame'] and require('gitblame').is_blame_text_available()
			end,
		},
	}

	-- TODO: export to ofirkai.nvim

	local lualine_a = nil
	local lualine_b = nil
	local lualine_y = nil
	local lualine_z = nil

	local kvim_icons = require('KoalaVim.utils.icons')

	local diagnostics_section = {
		'diagnostics',
		symbols = kvim_icons.pad_right(kvim_icons.diagnostics, ' '),
	}

	-- nvim-lualine/lualine.nvim
	if is_half then
		lualine_a = { { 'mode', separator = { left = '', right = '' }, padding = 0 } }
		lualine_b = {}
		lualine_y = {}
		lualine_z = {
			{ 'filetype', icon_only = true, separator = '', padding = 0 },
			{ 'location', padding = 0 },
		}
	else
		lualine_a = { { 'mode', separator = { left = '' } } }
		lualine_b = { { 'branch', icon = '' }, 'diff', diagnostics_section }
		lualine_y = y_section
		lualine_z = {
			{ 'filetype', padding = 0, separator = ' ' },
			{ 'location', padding = { left = 0, right = 1 } },
		}
	end

	local colors = {
		blue = '#80a0ff',
		dark_blue = '#688AA8',
		dark_blue_inactive = '#405b73',
		cyan = '#79dac8',
		black = '#080808',
		white = '#b4b4b4',
		real_white = '#c7c7c7',
		blueish_white = '#b8bdd4',
		red = '#ff5189',
		violet = '#d183e8',
		mid_blue = '#053957',
		dark_grey = '#2c2c2c',

		c_fg = '#051829',

		background_from_theme = '#080c10',
	}

	local bubbles_theme = {
		normal = {
			a = { fg = colors.black, bg = colors.dark_blue },
			b = { fg = colors.real_white, bg = colors.mid_blue },
			c = { fg = colors.blueish_white, bg = colors.c_fg },
		},

		insert = { a = { fg = colors.black, bg = '#8071A8' } },
		command = { a = { fg = colors.black, bg = '#A669A8' } },
		visual = { a = { fg = colors.black, bg = '#4CA86F' } },
		replace = { a = { fg = colors.black, bg = '#60A8A4' } },

		inactive = {
			a = { fg = colors.black, bg = colors.black },
			b = { fg = colors.white, bg = colors.dark_grey },
			c = { fg = colors.white, bg = colors.background_from_theme },
		},
	}

	local winbar = {
		lualine_b = {
			{
				'filename',
				path = 0,
				-- color = { fg = colors.black, bg = '#60A8A4' },
			},
		},
		lualine_c = {
			{
				function()
					return require('nvim-navic').get_location()
				end,
				cond = function()
					return package.loaded['nvim-navic'] and require('nvim-navic').is_available()
				end,
			},
			{
				function()
					return require('jsonpath').get()
				end,
				cond = function()
					if not package.loaded['jsonpath'] then
						return false
					end
					local ft = vim.api.nvim_buf_get_option(0, 'filetype')
					return ft == 'json' or ft == 'jsonc'
				end,
			},
		},
	}

	local inactive_winbar = {}
	local inactive_diagnostics_section = vim.tbl_extend('force', diagnostics_section, { separator = ' ', padding = 0 })

	-- inactive_winbar.lualine_b = winbar.lualine_b
	inactive_winbar.lualine_b = {
		{
			'filename',
			path = 1,
		},
	}
	inactive_winbar.lualine_c = {
		{
			function()
				-- empty for consistent left padding
				return ' '
			end,
			separator = '',
			padding = 0,
		},
		{ 'diff', separator = ' ', padding = 0 },
		inactive_diagnostics_section,
	}

	require('lualine').setup({
		options = {
			-- theme = M.lualine_opts.options.theme,
			theme = bubbles_theme,
			icons_enabled = true,
			path = 1,
			always_divide_middle = false,
			disabled_filetypes = {
				winbar = {
					'gitcommit',
					'NvimTree',
					'toggleterm',
					'fugitive',
					'floggraph',
					'git',
					'gitrebase',
					'quickfix',
					'alpha',
					'Trouble',
				},
			},
			globalstatus = true,

			-- Bubbles
			component_separators = '|',
			section_separators = { left = '', right = '' },
		},
		sections = {
			lualine_a = lualine_a,
			lualine_b = lualine_b,
			lualine_c = {
				{ 'filename', shorting_target = 0, icon = '' },
			},
			lualine_x = {
				{
					function()
						return gen_info_string('', 'RECORDING', icons_only) .. ' ' .. vim.fn.reg_recording()
					end,
					cond = function()
						return vim.fn.reg_recording() ~= ''
					end,
					separator = info_seperator,
					padding = 0,
				},
				{
					get_lsp_count,
					separator = ' | ',
					padding = 0,
				},
				{
					'searchcount',
					cond = function()
						return vim.fn.searchcount({ max_count = 1 }).total > 0
					end,
					fmt = function(str)
						return str:gsub('', '')
					end,
					icon = '',
					separator = ' │ ',
					padding = 0,
				},
				{
					-- TODO: add more info (shift width and such)
					function()
						if vim.b.Koala_tabs then
							return gen_info_string('', 'Tabs', icons_only)
						else
							return gen_info_string('󱁐', 'Spaces', icons_only)
						end
					end,
					separator = info_seperator,
					padding = 0,
				},
				{
					function()
						if KOALA_SESSION_LOADED or KOALA_AUTOSAVE_SESSION then
							return gen_info_string('', 'Session', icons_only)
						else
							return gen_info_string('', 'No Session', icons_only)
						end
					end,
					separator = info_seperator,
					padding = 0,
				},
				{
					get_current_lsp_server_name,
					icon = gen_info_string(nil, ' LSP:', icons_only),
					padding = { left = 0, right = 1 },
					separator = info_seperator,
				},
			},
			lualine_y = lualine_y,
			lualine_z = lualine_z,
		},
		winbar = winbar,
		inactive_winbar = inactive_winbar,
	})
end

return M
