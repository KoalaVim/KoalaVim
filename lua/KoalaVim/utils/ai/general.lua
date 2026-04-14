local M = {}

local SUPPORTED_AGENTS = { cursor = true, claude = true }

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

--- Opens a split with a temporary buffer for editing a prompt.
--- On closing the buffer, sends its content to sidekick CLI.
function M.edit_prompt()
	local agent = check_agent()
	if not agent then
		return
	end

	local get_prompt = agent == 'claude' and require('KoalaVim.utils.ai.claude').get_prompt
		or require('KoalaVim.utils.ai.cursor').get_prompt
	local current_prompt_lines = get_prompt()
	local bufid = vim.api.nvim_create_buf(false, true)
	local term_win = vim.api.nvim_get_current_win()

	-- Enter insert mode when focusing the buffer
	vim.api.nvim_create_autocmd('BufEnter', {
		buffer = bufid,
		once = true,
		callback = vim.schedule_wrap(function()
			-- Go to end and start in insert mode
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
			if content ~= '' then
				-- Using internal sidekick cli to not parse "{}" variables
				require('sidekick.cli.state').with(function(state)
					-- Clear current prompt content
					local termbufid = state.terminal.buf
					local clear_key = state.tool.name == 'claude' and '\x0c' or '\x03'
					vim.api.nvim_chan_send(vim.bo[termbufid].channel, clear_key)

					state.session:send(content)
				end, {
					attach = true,
					filter = {},
					focus = true,
					show = true,
				})
			end

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
	vim.api.nvim_buf_set_lines(bufid, 0, -1, false, current_prompt_lines)

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
			-- ret = { { " " }, { "@", "SidekickLocDelim" }, { "docs/loadbalancing-architecture.md", "SidekickLocFile" }, { " " } }
			local text = table.concat(
				vim.tbl_map(function(c)
					-- c[2] is highlight (if exist)
					return c[1]
				end, ret),
				''
			)
			vim.api.nvim_set_current_win(win_id)
			vim.api.nvim_put({ text }, '', true, true)
		end)
	end

	local picker = require('sidekick.cli.picker').get()

	-- FIXME: show hidden files in sidekick as well
	vim.keymap.set({ 'n', 'i' }, '<C-f>', function()
		picker.open('files', paste_to_buffer_cb, { hidden = true })
	end, { buffer = bufid })

	vim.keymap.set({ 'n', 'i' }, '<C-b>', function()
		picker.open('buffers', paste_to_buffer_cb, {})
	end, { buffer = bufid })
end

function M.nav_to_prompt(search_char)
	local agent = check_agent()
	if not agent then
		return
	end

	local pattern = agent == 'claude' and '❯' or ' ┌─'

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
		vim.o.showtabline = 2
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
	-- for new windows in the zoom tabpage
	zoom_ref_opts = {}
	local orig_tab = vim.api.nvim_get_current_tabpage()
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(orig_tab)) do
		if vim.bo[vim.api.nvim_win_get_buf(w)].filetype ~= 'sidekick_terminal' then
			for _, opt in ipairs(COPY_WIN_OPTS) do
				zoom_ref_opts[opt] = vim.wo[w][opt]
			end
			break
		end
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

	vim.o.showtabline = 0

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

return M
