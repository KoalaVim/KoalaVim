local M = {}

local api = vim.api

-- Using lazy modules as lib
local Git = require('lazy.manage.git')
local Config = require('lazy.core.config')
local Process = require('lazy.manage.process')

local function _check()
	-- Leverage lazy to fetch koala updates
	require('lazy').check({ plugins = { 'KoalaVim' }, show = false })

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

	local target = Git.get_target(koala_spec)
	if not curr then
		M.render('Git.get_target on ' .. koala_spec.dir .. ' failed', true)
		return
	end

	if Git.eq(curr, target) then
		return nil -- No updates
	end

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
			curr['commit'] .. '..' .. target.commit,
		},
		cwd = koala_spec.dir,
		on_exit = function(ok, output)
			M.render(output, not ok)
		end,
	})
end

local WIN_WIDTH = 65
local BASE_HEIGHT = 3
local MAX_COMMITS = 15

function M.render(message, error)
	if message == '' then
		return -- No updates to show. local git is ahead of remote probably
	end

	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(buf, 'filetype', 'KoalaUpdates')
	local ns = api.nvim_create_namespace('KoalaUpdates')

	api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	local title = 'New Koala Updates'
	local title_hl = 'Title'
	local border_hl = 'Number'
	if error then
		title = 'Failed to check for KoalaUpdates'
		title_hl = 'DiagnosticError'
		border_hl = 'DiagnosticError'
	end

	local margin = ''
	for _ = 1, math.floor(WIN_WIDTH / 2 - #title / 2), 1 do
		margin = margin .. ' '
	end

	title = margin .. title

	local spacer = ''
	for _ = 1, WIN_WIDTH, 1 do
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
		if #lines >= MAX_COMMITS then
			break
		end
	end

	api.nvim_buf_set_lines(buf, 2, -1, false, lines)

	local win = api.nvim_open_win(buf, false, {
		relative = 'editor',
		width = WIN_WIDTH,
		col = 1,
		row = 1,
		style = 'minimal',
		height = BASE_HEIGHT + #lines,
		border = 'rounded',
	})

	api.nvim_set_option_value('winhighlight', 'Normal:Normal,FloatBorder:' .. border_hl, { win = win })

	-- Clean pop up after alpha closed
	api.nvim_create_autocmd('User', {
		pattern = 'AlphaClosed',
		callback = function()
			if api.nvim_buf_is_valid(win) then
				api.nvim_win_close(win, true)
			end
			if api.nvim_buf_is_valid(buf) then
				api.nvim_buf_delete(buf, { force = true })
			end
		end,
	})
end

function M.check()
	vim.schedule(_check)
end

return M
