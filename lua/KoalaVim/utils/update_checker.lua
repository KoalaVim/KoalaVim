local M = {}

local api = vim.api

local kstate = require('KoalaVim').state
local kstate_manager = require('KoalaVim.state')
local UPDATE_FETCH_INTERVAL = 60 * 5 -- 5 mins
local PROGRESS = nil

local count = 0

-- Using lazy modules as lib
local Git = require('lazy.manage.git')
local Config = require('lazy.core.config')
local Process = require('lazy.manage.process')

local function _check_local_git()
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
		M.render('bdika ' .. count, false)
		count = count + 1
		return nil -- No updates
	end

	if KOALA_DASHBOARD_CLOSED then
		return nil
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

local function _on_lazy_check_done()
	-- update state
	kstate.last_update_check = os.time()
	kstate_manager.save()
	if PROGRESS then
		PROGRESS:finish()
	end
	_check_local_git()
end

local function _check()
	local last_update_check = kstate.last_update_check or 0
	if os.difftime(os.time(), last_update_check) < UPDATE_FETCH_INTERVAL then
		-- No need to fetch
		_check_local_git()
		return
	end

	PROGRESS = require('fidget.progress').handle.create({
		title = 'Checking for updates',
		lsp_client = { name = 'KoalaVim' },
		percentage = 0,
	})

	_check_local_git()

	-- Leverage lazy to fetch koala updates
	local res = require('lazy').check({ plugins = { 'KoalaVim' }, show = false })
	-- Show local results until lazy check is done
	res:wait(_on_lazy_check_done)
end

local WIN_WIDTH = 65
local BASE_HEIGHT = 3
local MAX_COMMITS = 15
local BUF = nil
local WIN = nil

function M.render(message, error)
	if message == '' then
		return -- No updates to show. local git is ahead of remote probably
	end

	if BUF then
		-- Clear buffer
		api.nvim_buf_set_lines(BUF, 1, -1, false, {})
	else
		BUF = api.nvim_create_buf(false, true)
	end
	api.nvim_buf_set_option(BUF, 'filetype', 'KoalaUpdates')
	local ns = api.nvim_create_namespace('KoalaUpdates')

	api.nvim_buf_clear_namespace(BUF, ns, 0, -1)

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

	api.nvim_buf_set_extmark(BUF, ns, 0, 0, {
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

	api.nvim_buf_set_lines(BUF, 2, -1, false, lines)

	if not WIN then
		WIN = api.nvim_open_win(BUF, false, {
			relative = 'editor',
			width = WIN_WIDTH,
			col = 1,
			row = 1,
			style = 'minimal',
			height = BASE_HEIGHT + #lines,
			border = 'rounded',
		})

		api.nvim_set_option_value('winhighlight', 'Normal:Normal,FloatBorder:' .. border_hl, { win = WIN })

		-- Clean pop up after alpha closed
		api.nvim_create_autocmd('User', {
			pattern = 'AlphaClosed',
			callback = function()
				if api.nvim_buf_is_valid(WIN) then
					api.nvim_win_close(WIN, true)
				end
				if api.nvim_buf_is_valid(BUF) then
					api.nvim_buf_delete(BUF, { force = true })
				end
			end,
		})
	end
end

function M.check()
	vim.schedule(_check)
end

return M
