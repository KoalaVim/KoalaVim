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

local DOWN = '\x1b[B' -- down arrow
local END_OF_LINE = '\x05' -- ctrl-e

-- `key` is sent to the terminal to clear the current prompt.
-- claude/cursor: ctrl-c clears the whole prompt in one shot.
-- codex: ctrl-u only clears a single line, so `per_line` makes us first move to
-- the end of the prompt (down once per line, then end-of-line) and then send the
-- key once per line (see send_to_sidekick).
local CLEAR_KEYS = {
	claude = { key = '\x03' },
	codex = { key = '\x15', per_line = true },
	cursor = { key = '\x03' },
}

local PROMPT_PATTERNS = {
	claude = '❯',
	codex = '^›',
	cursor = ' ┌─',
}

local PROMPT_START_ANCHOR = {
	claude = '❯',
	codex = '^›',
	cursor = '→',
}

local PROMPT_ANCHOR_OFFSETS = {
	claude = { row = -3, col = 1 },
	codex = { row = -3, col = 0 },
	cursor = { row = -2, col = 0 },
}

local CURSOR_ANCHOR_OFFSETS = {
	claude = { row = -3, col = 1 },
	codex = { row = -3, col = 0 },
	cursor = { row = -5, col = 0 },
}

local QUESTION_TUI_HANDLER = {
	cursor = function(prompt_lines)
		local cur = require('KoalaVim.utils.ai.cursor')
		if not cur.is_question_tui(prompt_lines) then
			return nil
		end
		return cur.get_question_prompt(prompt_lines), { key = '\x15' }
	end,
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

local function context_message(kind)
	return ({
		this = '{this}',
		file = '{file}',
		selection = '{selection}',
	})[kind]
end

local function find_prompt_win()
	local current_win = vim.api.nvim_get_current_win()
	if vim.bo[vim.api.nvim_win_get_buf(current_win)].filetype == 'sidekick_koala_prompt' then
		return current_win
	end

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) then
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].filetype == 'sidekick_koala_prompt' then
				return win
			end
		end
	end
end

---@param text sidekick.Text[]
local function insert_text_in_prompt(text)
	local prompt_win = find_prompt_win()
	if not prompt_win then
		return false
	end

	local lines = require('sidekick.text').lines(text)
	if vim.tbl_isempty(lines) then
		return true
	end

	vim.api.nvim_set_current_win(prompt_win)
	vim.api.nvim_put(lines, '', true, true)
	return true
end

local function render_context(kind)
	local text, handled = require('KoalaVim.utils.plugins.codediff').context_text(kind)
	if handled then
		return text, true
	end

	local msg = context_message(kind)
	if not msg then
		return nil, false
	end

	local _, rendered = require('sidekick.cli').render({ msg = msg })
	return rendered, rendered ~= nil
end

local function send_codediff_context(kind)
	local text, handled = require('KoalaVim.utils.plugins.codediff').context_text(kind)
	if handled then
		if text then
			M.with_default_tool(require('sidekick.cli').send, { text = text })
		end
		return true
	end
	return false
end

function M.send_context(kind)
	if find_prompt_win() then
		local text, handled = render_context(kind)
		if handled then
			if text then
				insert_text_in_prompt(text)
			end
			return
		end
	end

	if send_codediff_context(kind) then
		return
	end

	local msg = context_message(kind)
	if msg then
		M.with_default_tool(require('sidekick.cli').send, { msg = msg })
	end
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

local function get_ref_win_opts()
	local skip_ft = { sidekick_terminal = true, alpha = true }
	local tab = vim.api.nvim_get_current_tabpage()
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
		local win_config = vim.api.nvim_win_get_config(w)
		if win_config.relative == '' then
			local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
			if not skip_ft[ft] then
				local opts = {}
				for _, opt in ipairs(COPY_WIN_OPTS) do
					opts[opt] = vim.wo[w][opt]
				end
				return opts
			end
		end
	end
	return vim.tbl_extend('force', {}, DEFAULT_WIN_OPTS)
end

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
---@param clear_count? integer how many lines the current prompt has (default 1)
---@param clear_override? { key: string, per_line?: boolean }
function M.send_to_sidekick(content, agent, clear_count, clear_override)
	if content == '' then
		return
	end
	require('KoalaVim.utils.ai.history').append(content, agent)
	require('sidekick.cli.state').with(function(state)
		local termbufid = state.terminal.buf
		local clear = clear_override or CLEAR_KEYS[state.tool.name] or { key = '\x03' }
		local chan = vim.bo[termbufid].channel

		-- Clear whatever is currently in the prompt.
		if clear.per_line then
			local nlines = math.max(clear_count or 1, 1)
			-- Move to the end of the prompt (down once per line, then end-of-line),
			-- then clear each line.
			local seq = DOWN:rep(nlines) .. END_OF_LINE .. clear.key:rep(nlines * 2)
			vim.api.nvim_chan_send(chan, seq)
		else
			vim.api.nvim_chan_send(chan, clear.key)
		end

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
---@param clear_override? { key: string, per_line?: boolean }
---@param single_line? boolean join lines with spaces before sending
---@param bufid integer
---@param win_id integer
local function setup_prompt_split(bufid, win_id)
	vim.bo[bufid].filetype = 'sidekick_koala_prompt'
	vim.api.nvim_feedkeys('G$a ', 'n', false)

	local picker = require('sidekick.cli.picker').get()

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
			if vim.api.nvim_win_is_valid(win_id) then
				vim.api.nvim_set_current_win(win_id)
				vim.api.nvim_put({ text }, '', true, true)
			end
		end)
	end

	vim.keymap.set({ 'n', 'i' }, '<C-f>', function()
		picker.open('files', paste_to_buffer_cb, { hidden = true })
	end, { buffer = bufid })

	vim.keymap.set({ 'n', 'i' }, '<C-b>', function()
		picker.open('buffers', paste_to_buffer_cb, {})
	end, { buffer = bufid })
end

---@type { win: integer, row: number, col: number }?
local _prompt_anchor = nil

local function capture_prompt_anchor(agent)
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	local pattern = PROMPT_START_ANCHOR[agent]

	if pattern then
		local offsets = PROMPT_ANCHOR_OFFSETS[agent] or { row = 0, col = 0 }
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		for i = #lines, 1, -1 do
			if lines[i]:find(pattern) then
				_prompt_anchor = { win = win, row = i + offsets.row, col = offsets.col }
				return
			end
		end
	end

	local offsets = CURSOR_ANCHOR_OFFSETS[agent] or { row = 0, col = 0 }
	local pos = vim.api.nvim_win_get_cursor(win)
	_prompt_anchor = { win = win, row = pos[1] + offsets.row, col = offsets.col }
end

local function open_prompt_inline_float(bufid)
	local anchor = _prompt_anchor
	_prompt_anchor = nil

	local win_opts = {
		border = 'rounded',
		style = 'minimal',
	}

	if anchor and vim.api.nvim_win_is_valid(anchor.win) then
		win_opts.relative = 'win'
		win_opts.win = anchor.win
		win_opts.width = vim.api.nvim_win_get_width(anchor.win) - anchor.col - 2
		win_opts.height = vim.api.nvim_win_get_height(anchor.win) - anchor.row - 2
		win_opts.row = anchor.row
		win_opts.col = anchor.col
	else
		win_opts.relative = 'cursor'
		win_opts.width = vim.api.nvim_win_get_width(0)
		win_opts.row = 1
		win_opts.col = 0
	end

	local win = vim.api.nvim_open_win(bufid, true, win_opts)
	local ref_opts = get_ref_win_opts()
	for _, opt in ipairs(COPY_WIN_OPTS) do
		vim.wo[win][opt] = ref_opts[opt]
	end
	vim.api.nvim_set_hl(0, 'KoalaPromptBorder', { fg = '#3f478f' })
	vim.wo[win].winhighlight =
		'Normal:SidekickChat,NormalNC:SidekickChat,EndOfBuffer:EndOfBuffer,SignColumn:SidekickChat,FloatBorder:KoalaPromptBorder,LineNr:SidekickLineNr'
	vim.wo[win].signcolumn = 'no'
	return win
end

local function open_prompt_bottom_split(bufid)
	return vim.api.nvim_open_win(bufid, true, {
		split = 'below',
		height = math.ceil(vim.o.lines * 0.3),
	})
end

local function open_prompt_right_split(bufid)
	return vim.api.nvim_open_win(bufid, true, {
		split = 'right',
		width = math.ceil(vim.o.columns * 0.3),
	})
end

local LAYOUT_OPENERS = {
	['inline-float'] = open_prompt_inline_float,
	['bottom-30%'] = open_prompt_bottom_split,
	['right-30%'] = open_prompt_right_split,
}

local function open_prompt_win(bufid)
	local conf = require('KoalaVim').conf
	local layout = conf and conf.ai and conf.ai.edit_prompt_layout
	if not layout or layout == vim.NIL then
		layout = 'inline-float'
	end
	local opener = LAYOUT_OPENERS[layout] or open_prompt_inline_float
	return opener(bufid)
end

local function open_prompt_buffer(agent, initial_lines, term_win, clear_override, single_line)
	local bufid = vim.api.nvim_create_buf(false, true)

	-- Send content to sidekick CLI when closing the buffer
	vim.api.nvim_create_autocmd('BufWinLeave', {
		buffer = bufid,
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(bufid, 0, -1, false)
			local content = table.concat(lines, single_line and ' ' or '\n')
			M.send_to_sidekick(content, agent, #initial_lines, clear_override)

			if vim.api.nvim_win_is_valid(term_win) then
				vim.schedule(function()
					if vim.api.nvim_win_is_valid(term_win) then
						vim.api.nvim_set_current_win(term_win)
					end
				end)
			end
		end,
	})

	local win_id = open_prompt_win(bufid)
	vim.api.nvim_buf_set_lines(bufid, 0, -1, false, initial_lines)
	setup_prompt_split(bufid, win_id)

	vim.keymap.set({ 'n', 'i' }, '<M-r>', function()
		require('KoalaVim.utils.ai.history').pick('local')
	end, { buffer = bufid })
end

function M.is_question_active()
	local agent = check_agent()
	if not agent then
		return false
	end
	local handler = QUESTION_TUI_HANDLER[agent]
	if not handler then
		return false
	end
	local get_prompt = GET_PROMPT[agent]()
	local lines = get_prompt()
	local q_lines = handler(lines)
	return q_lines ~= nil
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
	local clear_override
	local single_line

	local question_handler = QUESTION_TUI_HANDLER[agent]
	if question_handler then
		local q_lines, clear = question_handler(current_prompt_lines)
		if q_lines then
			current_prompt_lines = q_lines
			clear_override = clear
			single_line = true
		end
	end

	local term_win = vim.api.nvim_get_current_win()
	open_prompt_buffer(agent, current_prompt_lines, term_win, clear_override, single_line)
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

local freeze_mod = require('KoalaVim.utils.ai.freeze_terminal')

function M.freeze_terminal(win, term_buf)
	freeze_mod.freeze(win, term_buf)
end

function M.is_terminal_frozen()
	return freeze_mod.is_frozen()
end

--- Freeze the terminal (claude only) and send Ctrl+G to trigger $EDITOR.
function M.send_editor_key()
	if freeze_mod.is_frozen() then
		return
	end
	local agent = M.get_attached_agent()
	capture_prompt_anchor(agent)
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	local chan = vim.bo[buf].channel
	if agent == 'claude' then
		freeze_mod.freeze(win, buf)
	end
	vim.api.nvim_chan_send(chan, '\x07')
end

--- Sessions keyed by FIFO path so concurrent `$EDITOR` invocations stay independent.
---@type table<string, { origin_win: integer }>
local editor_file_sessions = {}

--- Unblock the editor proxy. Fire-and-forget: opening a FIFO for write blocks
--- until a reader attaches, so this must not run on the main loop. A vanished
--- FIFO (proxy killed) fails in the child process, not here.
---@param pipe string
local function signal_editor_pipe(pipe)
	pcall(vim.system, { 'sh', '-c', 'echo done > ' .. vim.fn.shellescape(pipe) })
end

local function find_sidekick_terminal_win()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_is_valid(win) then
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].filetype == 'sidekick_terminal' then
				return win
			end
		end
	end
end

--- Open a CLI `$EDITOR` temp file in a split and signal `pipe` (FIFO) when
--- the user closes the buffer. Called via `v:lua` from the editor proxy.
--- Returns immediately so the proxy can attach its FIFO reader before any write.
---@param file string
---@param pipe string
---@return string
function M.open_editor_file(file, pipe)
	local origin_win = vim.api.nvim_get_current_win()
	local origin_mode = vim.fn.mode()
	editor_file_sessions[pipe] = { origin_win = origin_win, origin_mode = origin_mode }

	vim.schedule(function()
		local session = editor_file_sessions[pipe]
		if not session then
			return
		end

		if vim.api.nvim_win_is_valid(session.origin_win) then
			vim.api.nvim_set_current_win(session.origin_win)
		end

		local bufid = vim.fn.bufadd(file)
		vim.fn.bufload(bufid)
		local win_id = open_prompt_win(bufid)
		setup_prompt_split(bufid, win_id)

		vim.api.nvim_create_autocmd('BufWinLeave', {
			buffer = bufid,
			once = true,
			callback = function()
				editor_file_sessions[pipe] = nil

				if vim.bo[bufid].modified then
					local ok, err = pcall(function()
						vim.api.nvim_buf_call(bufid, function()
							vim.cmd.update()
						end)
					end)
					if not ok then
						vim.notify('Failed to write editor file: ' .. tostring(err), vim.log.levels.WARN)
					end
				end

				signal_editor_pipe(pipe)
				freeze_mod.unfreeze()

				local term_win = find_sidekick_terminal_win()
				if not term_win or not vim.api.nvim_win_is_valid(term_win) then
					term_win = session.origin_win
				end
				if vim.api.nvim_win_is_valid(term_win) then
					vim.schedule(function()
						if vim.api.nvim_win_is_valid(term_win) then
							vim.api.nvim_set_current_win(term_win)
							if session.origin_mode == 't' then
								vim.cmd.startinsert()
							end
						end
					end)
				end
			end,
		})
	end)

	return ''
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

	zoom_ref_opts = get_ref_win_opts()

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
