local M = {}

--- Opens a split with a temporary buffer for editing a prompt.
--- On closing the buffer, sends its content to sidekick CLI.
function M.edit_prompt()
	local current_prompt_lines = require('KoalaVim.utils.ai.cursor').get_prompt()
	local bufid = vim.api.nvim_create_buf(false, true)

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
					-- FIXME: cursor only?
					-- Clear current prompt content: Sends C+c
					local termbufid = state.terminal.buf
					vim.api.nvim_chan_send(vim.bo[termbufid].channel, '\x03')

					state.session:send(content)
				end, {
					attach = true,
					filter = {},
					focus = true,
					show = true,
				})
			end
		end,
	})

	vim.cmd('split')
	local win_id = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(0, bufid)
	vim.api.nvim_win_set_height(0, math.ceil(vim.o.lines * 0.3))
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
	-- in claude: ❯
	local f = function()
		vim.fn.setreg('/', ' ┌─')
		vim.cmd('normal! ' .. search_char)
	end

	if vim.fn.mode() == 't' then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true), 'n', false)
		f = vim.schedule_wrap(f)
	end
	f()
end

function M.get_attached_agent()
	-- FIXME: detect which agent sidekick runs
	-- require("sidekick.cli.state").get({attached = true})[1]['tool']['name'])
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
