local M = {}

local SUPPORTED_AGENTS = { cursor = true, claude = true, codex = true }

local GET_PROMPT = {
	claude = function()
		return require('KoalaVim.utils.ai.claude').get_prompt
	end,
	codex = function()
		return require('KoalaVim.utils.ai.codex').get_prompt
	end,
	cursor = function()
		return require('KoalaVim.utils.ai.cursor').get_prompt
	end,
}

local CLEAR_KEYS = {
	claude = '\x03',
	codex = '\x15',
	cursor = '\x03',
}

local PROMPT_PATTERNS = {
	claude = '❯',
	codex = '^›',
	cursor = ' ┌─',
}

--- Debug why a key (default: space) feels slow in the current terminal buffer.
--- Call from the sidekick terminal buffer (after `<C-\><C-n>` to exit term mode):
---   :lua require('KoalaVim.utils.ai.general').debug_slow_key()
---   :lua require('KoalaVim.utils.ai.general').debug_slow_key('<Tab>')
---@param key? string  lhs to inspect (default ' ')
function M.debug_slow_key(key)
	key = key or ' '
	local norm_key = vim.api.nvim_replace_termcodes(key, true, true, true)
	local out = {}

	out.buffer = vim.api.nvim_get_current_buf()
	out.filetype = vim.bo.filetype
	out.timeout = vim.o.timeout
	out.timeoutlen = vim.o.timeoutlen
	out.ttimeout = vim.o.ttimeout
	out.ttimeoutlen = vim.o.ttimeoutlen

	-- Direct lookups
	out.maparg_t = vim.fn.maparg(norm_key, 't', false, true)
	out.mapcheck_t = vim.fn.mapcheck(norm_key, 't')

	-- Every t-mode mapping whose lhs starts with (or equals) this key
	local function matches(lhs)
		local lhs_norm = vim.api.nvim_replace_termcodes(lhs, true, true, true)
		return lhs_norm:sub(1, #norm_key) == norm_key
	end

	out.global_t_prefix = {}
	for _, m in ipairs(vim.api.nvim_get_keymap('t')) do
		if matches(m.lhs) then
			table.insert(out.global_t_prefix, { lhs = m.lhs, rhs = m.rhs, desc = m.desc, sid = m.sid })
		end
	end

	out.buffer_t_prefix = {}
	for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, 't')) do
		if matches(m.lhs) then
			table.insert(out.buffer_t_prefix, { lhs = m.lhs, rhs = m.rhs, desc = m.desc, sid = m.sid })
		end
	end

	-- Active on_key handlers (can also impose per-keystroke cost)
	out.on_key_ns_count = 0
	for _ in pairs(vim.api.nvim_get_namespaces()) do
		out.on_key_ns_count = out.on_key_ns_count + 1
	end

	vim.print(out)
	return out
end

-- Session-scoped default tool, initialized from koala config
local _default_tool = nil

function M.get_default_tool()
	if _default_tool then
		return _default_tool
	end
	local conf = require('KoalaVim').conf
	if conf and conf.ai and conf.ai.default_tool and conf.ai.default_tool ~= vim.NIL then
		return conf.ai.default_tool
	end
	return nil
end

function M.set_default_tool(name)
	_default_tool = name
end

--- Runs a sidekick cli function with the default tool.
--- If a default is set, calls the action directly with that tool name.
--- Otherwise, prompts an installed-only selection first.
---@param action fun(opts: table)
---@param extra? table additional args to merge
function M.with_default_tool(action, extra)
	local name = M.get_default_tool()
	if name then
		local args = { name = name }
		if extra then
			args = vim.tbl_extend('force', args, extra)
		end
		action(args)
	else
		require('sidekick.cli').select({
			filter = { installed = true },
			cb = function(state)
				if state then
					_default_tool = state.tool.name
					local args = { name = state.tool.name }
					if extra then
						args = vim.tbl_extend('force', args, extra)
					end
					action(args)
				end
			end,
		})
	end
end

local zoom_tabpage = nil
local zoom_orig_win = nil
local zoom_ref_opts = nil

local COPY_WIN_OPTS = {
	'winhighlight',
	'signcolumn',
	'number',
	'relativenumber',
	'wrap',
	'cursorline',
	'cursorcolumn',
	'colorcolumn',
	'fillchars',
	'list',
	'listchars',
	'sidescrolloff',
	'statuscolumn',
	'spell',
	'winbar',
}

-- Capture user's default option values at module load time (before sidekick pollutes globals)
local DEFAULT_WIN_OPTS = {}
for _, opt in ipairs(COPY_WIN_OPTS) do
	DEFAULT_WIN_OPTS[opt] = vim.api.nvim_get_option_value(opt, { scope = 'global' })
end
DEFAULT_WIN_OPTS['winhighlight'] = ''

local function check_agent()
	local agent = M.get_attached_agent()
	if not agent then
		vim.notify('No AI agent attached', vim.log.levels.WARN)
		return nil
	end
	if not SUPPORTED_AGENTS[agent] then
		vim.notify('Unsupported AI agent: ' .. agent, vim.log.levels.WARN)
		return nil
	end
	return agent
end

--- Send `content` to the attached sidekick CLI, clearing whatever is
--- currently in the prompt first, and record it in prompt history.
---@param content string
---@param agent string
function M.send_to_sidekick(content, agent)
	if content == '' then
		return
	end
	require('KoalaVim.utils.ai.history').append(content, agent)
	require('sidekick.cli.state').with(function(state)
		local termbufid = state.terminal.buf
		local clear_key = CLEAR_KEYS[state.tool.name] or '\x03'
		vim.api.nvim_chan_send(vim.bo[termbufid].channel, clear_key)
		state.session:send(content)
	end, {
		attach = true,
		filter = {},
		focus = true,
		show = true,
	})
end

--- Opens a split with a temporary buffer for editing a prompt and sends it
--- to the sidekick CLI on close. `initial_lines` is the prefilled content.
---@param agent string
---@param initial_lines string[]
---@param term_win integer the window to refocus after closing
local function open_prompt_buffer(agent, initial_lines, term_win)
	local bufid = vim.api.nvim_create_buf(false, true)

	-- Enter insert mode when focusing the buffer
	vim.api.nvim_create_autocmd('BufEnter', {
		buffer = bufid,
		once = true,
		callback = vim.schedule_wrap(function()
			vim.api.nvim_feedkeys('G$a', 'n', false)
		end),
	})

	-- Send content to sidekick CLI when closing the buffer
	vim.api.nvim_create_autocmd('BufWinLeave', {
		buffer = bufid,
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(bufid, 0, -1, false)
			local content = table.concat(lines, '\n')
			-- Using internal sidekick cli to not parse "{}" variables
			M.send_to_sidekick(content, agent)

			-- Re-focus the terminal window so we stay in the same tabpage
			if vim.api.nvim_win_is_valid(term_win) then
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(term_win) then
						vim.api.nvim_set_current_win(term_win)
					end
				end)
			end
		end,
	})

	local win_id = vim.api.nvim_open_win(bufid, true, {
		split = 'below',
		height = math.ceil(vim.o.lines * 0.3),
	})

	vim.bo[bufid].filetype = 'sidekick_koala_prompt'
	vim.api.nvim_buf_set_lines(bufid, 0, -1, false, initial_lines)

	---@param items sidekick.context.Loc[]
	local paste_to_buffer_cb = function(items)
		local Loc = require('sidekick.cli.context.location')
		local ret = { { ' ' } } ---@type sidekick.Text
		for _, item in ipairs(items) do
			local file = Loc.get(item, { kind = 'file' })[1]
			if file then
				vim.list_extend(ret, file)
				ret[#ret + 1] = { ' ' }
			end
		end
		vim.schedule(function()
			local text = table.concat(
				vim.tbl_map(function(c)
					return c[1]
				end, ret),
				''
			)
			vim.api.nvim_set_current_win(win_id)
			vim.api.nvim_put({ text }, '', true, true)
		end)
	end

	local picker = require('sidekick.cli.picker').get()

	vim.keymap.set({ 'n', 'i' }, '<C-f>', function()
		picker.open('files', paste_to_buffer_cb, { hidden = true })
	end, { buffer = bufid })

	vim.keymap.set({ 'n', 'i' }, '<C-b>', function()
		picker.open('buffers', paste_to_buffer_cb, {})
	end, { buffer = bufid })

	vim.keymap.set({ 'n', 'i' }, '<C-r>', function()
		require('KoalaVim.utils.ai.history').pick('local')
	end, { buffer = bufid })
end

--- Opens a split with a temporary buffer for editing a prompt.
--- On closing the buffer, sends its content to sidekick CLI.
function M.edit_prompt()
	local agent = check_agent()
	if not agent then
		return
	end

	local get_prompt = GET_PROMPT[agent]()
	local current_prompt_lines = get_prompt()
	local term_win = vim.api.nvim_get_current_win()

	open_prompt_buffer(agent, current_prompt_lines, term_win)
end

--- Open the edit-prompt buffer prefilled with arbitrary content.
--- Used by the history picker to "load" a past prompt.
---@param content string
function M.open_prompt_with(content)
	local agent = check_agent()
	if not agent then
		return
	end
	local term_win = vim.api.nvim_get_current_win()
	local lines = vim.split(content, '\n', { plain = true })
	open_prompt_buffer(agent, lines, term_win)
end

function M.nav_to_prompt(search_char)
	local agent = check_agent()
	if not agent then
		return
	end

	local pattern = PROMPT_PATTERNS[agent]

	local f = function()
		vim.fn.setreg('/', pattern)
		vim.cmd('normal! ' .. search_char)
	end

	if vim.fn.mode() == 't' then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true), 'n', false)
		f = vim.schedule_wrap(f)
	end
	f()
end

function M.get_attached_agent()
	-- Check if the current buffer is a sidekick terminal
	local tool = vim.b.sidekick_cli
	if tool then
		return tool.name
	end

	-- Check if any window in the current tabpage is a sidekick terminal
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		tool = vim.w[win].sidekick_cli
		if tool then
			return tool.name
		end
	end

	-- Fallback: first attached session
	local states = require('sidekick.cli.state').get({ attached = true })
	if #states > 0 then
		return states[1].tool.name
	end
end

--- Zoom a sidekick terminal into a dedicated tabpage.
---
--- Problem: when zooming, we create a new tabpage and display the sidekick terminal buffer in it.
--- Any new window created in this tabpage (edit_prompt, neogit, codediff, :new) inherits the
--- sidekick terminal's window-local options (winhighlight, signcolumn, number, etc.) because
--- vim's :split / nvim_open_win always copies window options from the parent window.
---
--- Solutions that didn't work:
--- - nvim_get_option_value(opt, { scope = 'global' }): sidekick pollutes global values
--- - nvim_get_option_info2(opt, {}).default: returns vim builtin defaults, not user config
--- - Anchor window (clean scratch buffer kept at 1 row): worked for style but caused layout
---   issues, dirty buffer visible, and didn't help windows in other tabpages (codediff)
--- - Opening a temp buffer/window before tabnew to get clean context: same inheritance issue
--- - style = "minimal" in nvim_open_win: resets too much and appends to winhighlight
---
--- Current solution: at zoom time, capture window options from a normal editor window in the
--- original tabpage. A WinNew autocmd detects new windows that inherited sidekick's winhighlight
--- (containing 'SidekickChat') and resets their options to the captured reference values.
--- This works across tabpages (codediff) and lets plugins (neogit) override afterwards.
function M.zoom_sidekick()
	if zoom_tabpage and vim.api.nvim_tabpage_is_valid(zoom_tabpage) then
		-- Unzoom: close the tabpage
		pcall(vim.api.nvim_del_augroup_by_name, 'ZoomSidekickWinNew')
		vim.api.nvim_set_current_tabpage(zoom_tabpage)
		vim.cmd('tabclose')
		-- vim.o.showtabline = 2
		zoom_tabpage = nil
		zoom_ref_opts = nil
		if zoom_orig_win and vim.api.nvim_win_is_valid(zoom_orig_win) then
			vim.api.nvim_set_current_win(zoom_orig_win)
		end
		zoom_orig_win = nil
		return
	end

	local orig_win = vim.api.nvim_get_current_win()
	local termbuf = vim.api.nvim_get_current_buf()

	-- Capture options from a normal editor window to use as defaults
	-- for new windows in the zoom tabpage.
	-- Skip sidekick terminals and special buffers (alpha, etc.) that have
	-- non-standard options. Fall back to vim.opt values if no suitable window found.
	zoom_ref_opts = {}
	local skip_ft = { sidekick_terminal = true, alpha = true }
	local ref_found = false
	local orig_tab = vim.api.nvim_get_current_tabpage()
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(orig_tab)) do
		-- Skip floating windows (notifications, popups, etc.)
		local win_config = vim.api.nvim_win_get_config(w)
		if win_config.relative ~= '' then
			goto continue
		end
		local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
		if not skip_ft[ft] then
			for _, opt in ipairs(COPY_WIN_OPTS) do
				zoom_ref_opts[opt] = vim.wo[w][opt]
			end
			ref_found = true
			break
		end
		::continue::
	end
	if not ref_found then
		-- No suitable reference window, use defaults captured at module load time
		zoom_ref_opts = vim.tbl_extend('force', {}, DEFAULT_WIN_OPTS)
	end

	vim.cmd('tabnew')
	zoom_tabpage = vim.api.nvim_get_current_tabpage()
	local zoom_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(zoom_win, termbuf)

	-- Copy window options from the original sidekick window
	for _, opt in ipairs(COPY_WIN_OPTS) do
		vim.wo[zoom_win][opt] = vim.wo[orig_win][opt]
	end
	vim.wo[zoom_win].winbar = ''

	-- Reset inherited sidekick options on any new window in the zoom tabpage
	local zoom_augroup = vim.api.nvim_create_augroup('ZoomSidekickWinNew', { clear = true })
	vim.api.nvim_create_autocmd('WinNew', {
		group = zoom_augroup,
		callback = function()
			local new_win = vim.api.nvim_get_current_win()
			-- Skip the sidekick terminal window itself
			if new_win == zoom_win then
				return
			end
			-- Only reset windows that inherited sidekick's winhighlight
			local whl = vim.wo[new_win].winhighlight
			if whl == '' or not whl:find('SidekickChat') then
				return
			end
			for _, opt in ipairs(COPY_WIN_OPTS) do
				vim.wo[new_win][opt] = zoom_ref_opts[opt]
			end
		end,
	})

	-- vim.o.showtabline = 0

	zoom_orig_win = orig_win
end

local HALF_RATIO = 0.5
local MAX_RATIO = 0.95

function M.toggle_max()
	if vim.bo.filetype ~= 'sidekick_terminal' then
		return
	end

	local cols = vim.o.columns
	local win_width = vim.api.nvim_win_get_width(0)
	local half_width = math.floor(cols * HALF_RATIO)
	local max_width = math.floor(cols * MAX_RATIO)

	-- vim.print({ cols = cols, win_width = win_width, half_width = half_width, max_width = max_width })
	if win_width < half_width or win_width >= max_width then
		vim.api.nvim_win_set_width(0, half_width)
	else
		vim.api.nvim_win_set_width(0, max_width)
	end
end

-- Fast-typing detection: trigger edit_prompt when `count` printable keystrokes
-- land inside a sliding `window_ms` window (i.e. typing speed >= count chars
-- per window_ms). Lower window_ms or higher count = stricter (fewer false
-- triggers on stray key mashing); higher window_ms or lower count = more eager
-- switch. `render_delay_ms` is unrelated to sensitivity — it's the grace
-- period after the last keystroke before we read the terminal buffer, so the
-- CLI has time to render the typed chars into the buffer for get_prompt() to
-- pick up.
local typing_times = {}
local fast_typing_armed = true

function M.setup_fast_typing_detection()
	local conf = require('KoalaVim').conf
	local auto = conf and conf.ai and conf.ai.auto_edit_prompt or {}
	if auto.enabled ~= true then
		return
	end

	local count = auto.count or 8
	local window_ms = auto.window_ms or 650
	local render_delay_ms = auto.render_delay_ms or 80

	vim.on_key(function(_, typed)
		if not fast_typing_armed then
			return
		end
		if vim.bo.filetype ~= 'sidekick_terminal' or vim.fn.mode() ~= 't' then
			if #typing_times > 0 then
				typing_times = {}
			end
			return
		end
		if type(typed) ~= 'string' or #typed ~= 1 then
			typing_times = {}
			return
		end
		local b = typed:byte()
		if b < 32 or b > 126 then
			typing_times = {}
			return
		end

		local now = vim.uv.hrtime() / 1e6
		table.insert(typing_times, now)
		while typing_times[1] and now - typing_times[1] > window_ms do
			table.remove(typing_times, 1)
		end

		if #typing_times >= count then
			typing_times = {}
			fast_typing_armed = false

			-- Block terminal input during the render grace period so in-flight
			-- keystrokes aren't lost between snapshotting the prompt and
			-- opening the edit buffer. Printable chars typed in the meantime
			-- are captured and later inserted into the edit buffer.
			local term_buf = vim.api.nvim_get_current_buf()
			local captured = {}
			local printable = {}
			for bb = 32, 126 do
				printable[#printable + 1] = string.char(bb)
			end
			for _, ch in ipairs(printable) do
				pcall(vim.keymap.set, 't', ch, function()
					captured[#captured + 1] = ch
				end, { buffer = term_buf, silent = true })
			end

			vim.defer_fn(function()
				for _, ch in ipairs(printable) do
					pcall(vim.keymap.del, 't', ch, { buffer = term_buf })
				end
				if vim.bo.filetype == 'sidekick_terminal' then
					M.edit_prompt()
					if #captured > 0 then
						vim.schedule(function()
							vim.api.nvim_put({ table.concat(captured) }, 'c', true, true)
						end)
					end
				end
				fast_typing_armed = true
			end, render_delay_ms)
		end
	end)
end

return M
