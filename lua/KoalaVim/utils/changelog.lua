local M = {}

local api = vim.api

-- Using lazy modules as lib
local Git = require('lazy.manage.git')
local Config = require('lazy.core.config')
local Process = require('lazy.manage.process')

function M.check()
	local koala_spec = Config.plugins['KoalaVim']
	if not koala_spec then
		M.render("didn't find KoalaVim in plugins spec", true)
		return
	end

	local curr = Git.info(koala_spec.dir)
	if not curr then
		M.render('Git.info on ' .. koala_spec.dir .. ' failed', true)
		return
	end

	local from = 'HEAD~100'

	-- Get git log
	Process.spawn('git', {
		args = {
			'log',
			'--pretty=format:%s (%cr)',
			'--abbrev-commit',
			'--decorate',
			'--date=short',
			'--color=never',
			'--no-show-signature',
			from .. '..HEAD',
		},
		cwd = koala_spec.dir,
		on_exit = function(ok, output)
			M.render(output, not ok)
		end,
	})
end

local MAX_WIN_WIDTH = 120
local BASE_HEIGHT = 3

function M.render(message, error)
	local buf = api.nvim_create_buf(false, true)
	vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf })

	api.nvim_buf_set_option(buf, 'filetype', 'KoalaChangeLog')
	local ns = api.nvim_create_namespace('KoalaChangeLog')

	api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	local title = 'Koala Changelog'
	local title_hl = 'Title'
	local border_hl = 'Number'
	if error then
		title = 'Failed to get changelog'
		title_hl = 'DiagnosticError'
		border_hl = 'DiagnosticError'
	end

	local nvim_width = api.nvim_get_option_value('columns', {})
	local win_width = math.min(nvim_width, MAX_WIN_WIDTH)

	local margin = ''
	for _ = 1, math.floor(win_width / 2 - #title / 2), 1 do
		margin = margin .. ' '
	end

	title = margin .. title

	local spacer = ''
	for _ = 1, win_width, 1 do
		spacer = spacer .. '─'
	end

	api.nvim_buf_set_extmark(buf, ns, 0, 0, {
		virt_text_pos = 'overlay',
		virt_text = { { title, title_hl } },
		virt_lines = { { { spacer, 'FloatBorder' } } },
	})

	local lines = {}
	for line in string.gmatch(message, '[^\n]+') do
		table.insert(lines, ' * ' .. line)
	end

	api.nvim_buf_set_lines(buf, 2, -1, false, lines)

	local max_height = api.nvim_get_option_value('lines', {}) - 5

	local win = api.nvim_open_win(buf, true, {
		relative = 'editor',
		width = win_width,
		col = nvim_width / 2 - win_width / 2,
		row = 1,
		style = 'minimal',
		height = math.min(BASE_HEIGHT + #lines, max_height),
		border = 'rounded',
	})

	api.nvim_set_option_value('winhighlight', 'Normal:Normal,FloatBorder:' .. border_hl, { win = win })

	local close_pop_up = function()
		if api.nvim_win_is_valid(win) then
			api.nvim_win_close(win, true)
		end
		if api.nvim_buf_is_valid(buf) then
			api.nvim_buf_delete(buf, { force = true })
		end
	end

	-- Clean pop up after alpha closed
	api.nvim_create_autocmd('User', {
		pattern = 'AlphaClosed',
		callback = close_pop_up,
	})

	-- Clean pop up after losing focus of the dashboard
	api.nvim_create_autocmd('WinLeave', {
		callback = function(events)
			local ft = vim.bo[events.buf].ft
			if ft == 'alpha' or ft == 'KoalaChangeLog' then
				close_pop_up()
			end
		end,
	})
end

return M
