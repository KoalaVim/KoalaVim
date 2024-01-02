local M = {}

M.lualine_opts = {}

local function get_current_lsp_server_name()
	local msg = '———'
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

function M.setup_lualine(is_half, opts)
	if opts then
		M.lualine_opts = opts
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
						return ' RECORDING ' .. vim.fn.reg_recording()
					end,
					cond = function()
						return vim.fn.reg_recording() ~= ''
					end,
					separator = '|',
				},
				{
					'searchcount',
					separator = '|',
					icon = '',
				},
				{
					-- TODO: add more info (shift width and such)
					function()
						if vim.b.Koala_tabs then
							return ' Tabs'
						else
							return '󱁐 Spaces'
						end
					end,
					separator = '|',
				},
				{
					function()
						if KOALA_SESSION_LOADED or KOALA_AUTOSAVE_SESSION then
							return ' Session'
						else
							return ' No Session'
						end
					end,
					separator = '|',
				},
				{ get_current_lsp_server_name, icon = ' LSP:' },
			},
			lualine_y = lualine_y,
			lualine_z = lualine_z,
		},
		winbar = winbar,
		inactive_winbar = inactive_winbar,
	})
end

return M
