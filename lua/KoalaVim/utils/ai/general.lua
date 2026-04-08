local M = {}

local SUPPORTED_AGENTS = { cursor = true, claude = true }

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
	local termbuf = vim.api.nvim_get_current_buf()
	local bufid = vim.api.nvim_create_buf(false, true)

	local is_zoomed = pcall(require, 'neo-zoom') and require('neo-zoom').did_zoom()[1]
	local zoom_tabpage = nil

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

			-- Close the zoom tabpage if we created one
			if zoom_tabpage and vim.api.nvim_tabpage_is_valid(zoom_tabpage) then
				vim.schedule(function()
					if vim.api.nvim_tabpage_is_valid(zoom_tabpage) then
						vim.api.nvim_set_current_tabpage(zoom_tabpage)
						vim.cmd('tabclose')
					end
				end)
			end
		end,
	})

	local win_id
	if is_zoomed then
		-- Create a new tabpage with sidekick terminal + edit prompt
		local orig_win = vim.api.nvim_get_current_win()
		vim.cmd('tabnew')
		zoom_tabpage = vim.api.nvim_get_current_tabpage()
		-- Split first so the edit prompt window gets default options
		vim.cmd('split')
		win_id = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win_id, bufid)
		vim.api.nvim_win_set_height(win_id, math.ceil(vim.o.lines * 0.3))
		-- Set terminal buffer in the top window and copy its style
		local term_win = vim.fn.win_getid(vim.fn.winnr('#'))
		vim.api.nvim_win_set_buf(term_win, termbuf)
		local copy_opts = { 'winhighlight', 'signcolumn', 'number', 'relativenumber', 'wrap',
			'cursorline', 'cursorcolumn', 'colorcolumn', 'fillchars', 'list', 'listchars',
			'sidescrolloff', 'statuscolumn', 'spell', 'winbar' }
		for _, opt in ipairs(copy_opts) do
			vim.wo[term_win][opt] = vim.wo[orig_win][opt]
		end
	else
		vim.cmd('split')
		win_id = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(0, bufid)
		vim.api.nvim_win_set_height(0, math.ceil(vim.o.lines * 0.3))
	end
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
