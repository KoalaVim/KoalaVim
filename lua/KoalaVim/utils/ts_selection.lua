-- Treesitter incremental selection.
--  normal `<C-Space>` selects the node under the cursor
--  visual `<C-Space>` expands the selection to the next larger node
--  visual `<BS>` shrinks back through the expansions
--
-- The `*_expr` functions are meant for `expr = true` mappings, they return a no-op (`<C-Space>`)
-- or the original key (`<BS>`) when the selection doesn't apply (buffer without a parser,
-- special buffers, ...) so the key keeps its default behavior there.
local M = {}

local api = vim.api

local MODULE = "require('KoalaVim.utils.ts_selection')"

---@alias KoalaVim.TSRange integer[] {start_row, start_col, end_row, end_col}, 0-indexed, end is exclusive

---@class KoalaVim.TSSelectionStack
---@field tick integer changedtick of the buffer when the stack was written
---@field ranges KoalaVim.TSRange[] selections history, the last one is the current selection

---Selection stack per buffer. A stack is valid only while the buffer is untouched and the
---current visual selection equals the last range of the stack, otherwise it's dropped.
---@type table<integer, KoalaVim.TSSelectionStack>
local stacks = {}

api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, {
	group = api.nvim_create_augroup('koala_ts_selection', { clear = true }),
	callback = function(ev)
		stacks[ev.buf] = nil
	end,
})

---@param buf integer
---@return vim.treesitter.LanguageTree?
local function get_parser(buf)
	-- Special buffers (quickfix, cmdwin, terminal, prompts, ...) keep their `<CR>`
	if vim.bo[buf].buftype ~= '' then
		return nil
	end
	return vim.treesitter.get_parser(buf, nil, { error = false })
end

---The named node under the cursor
---@param buf integer
---@return TSNode?
local function get_node(buf)
	local parser = get_parser(buf)
	if not parser then
		return nil
	end
	parser:parse() -- the buffer might not be parsed yet (not drawn)
	return vim.treesitter.get_node({ bufnr = buf })
end

---@param buf integer
---@param row integer
---@return string
local function get_line(buf, row)
	return api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
end

---A range ending at column 0 really ends at the previous line.
---@param buf integer
---@param r KoalaVim.TSRange
---@return KoalaVim.TSRange
local function normalize(buf, r)
	local sr, sc, er, ec = unpack(r)
	if ec == 0 and er > sr then
		er = er - 1
		ec = #get_line(buf, er)
	end
	return { sr, sc, er, ec }
end

---@param a KoalaVim.TSRange
---@param b KoalaVim.TSRange
local function equal(a, b)
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

---@param outer KoalaVim.TSRange
---@param inner KoalaVim.TSRange
local function contains(outer, inner)
	local starts_before = outer[1] < inner[1] or (outer[1] == inner[1] and outer[2] <= inner[2])
	local ends_after = outer[3] > inner[3] or (outer[3] == inner[3] and outer[4] >= inner[4])
	return starts_before and ends_after
end

---The current visual selection as a (0-indexed, end exclusive) range.
---@param buf integer
---@return KoalaVim.TSRange
local function visual_range(buf)
	local a, b = vim.fn.getpos('v'), vim.fn.getpos('.')
	if a[2] > b[2] or (a[2] == b[2] and a[3] > b[3]) then
		a, b = b, a
	end

	local sr, sc = a[2] - 1, a[3] - 1
	local er, ec = b[2] - 1, b[3] - 1
	local line = get_line(buf, er)
	if vim.fn.mode() == 'V' then
		sc, ec = 0, #line
	elseif ec < #line then
		ec = math.min(ec + vim.str_utf_end(line, ec + 1) + 1, #line) -- make the end exclusive
	end
	return { sr, sc, er, ec }
end

---Select a range charwise.
---@param buf integer
---@param r KoalaVim.TSRange normalized range
local function select_range(buf, r)
	local sr, sc, er, ec = unpack(r)
	local line = get_line(buf, er)

	-- Last selected char, `ec` is exclusive and may point in the middle of a multibyte char
	local last_col = 0
	if ec > 0 then
		last_col = ec - 1 + vim.str_utf_start(line, ec)
	end

	if vim.fn.mode() ~= 'n' then
		vim.cmd.normal({ args = { vim.keycode('<Esc>') }, bang = true })
	end
	api.nvim_win_set_cursor(0, { sr + 1, sc })
	vim.cmd.normal({ args = { 'v' }, bang = true })
	api.nvim_win_set_cursor(0, { er + 1, last_col })
end

---The smallest node that is larger than the range.
---@param buf integer
---@param r KoalaVim.TSRange normalized range
---@return KoalaVim.TSRange?
local function larger_range(buf, r)
	local parser = get_parser(buf)
	if not parser then
		return nil
	end
	parser:parse()

	local node = parser:named_node_for_range(r)
	while node do
		local node_range = normalize(buf, { node:range() })
		if contains(node_range, r) and not equal(node_range, r) then
			return node_range
		end
		node = node:parent()
	end
	return nil
end

---@param buf integer
---@return KoalaVim.TSSelectionStack? stack only if it matches the current visual selection
local function get_valid_stack(buf)
	local stack = stacks[buf]
	if not stack then
		return nil
	end

	local valid = stack.tick == api.nvim_buf_get_changedtick(buf)
		and equal(stack.ranges[#stack.ranges], visual_range(buf))
	if not valid then
		stacks[buf] = nil
		return nil
	end
	return stack
end

---Select the node under the cursor.
function M.start()
	local buf = api.nvim_get_current_buf()
	local node = get_node(buf)
	if not node then
		return
	end

	select_range(buf, normalize(buf, { node:range() }))
	stacks[buf] = { tick = api.nvim_buf_get_changedtick(buf), ranges = { visual_range(buf) } }
end

---Expand the visual selection to the next larger node.
function M.expand()
	local buf = api.nvim_get_current_buf()
	local stack = get_valid_stack(buf)
	if not stack then
		-- Selection made outside of this module, start a new history from it
		stack = { tick = api.nvim_buf_get_changedtick(buf), ranges = { visual_range(buf) } }
		stacks[buf] = stack
	end

	local r = larger_range(buf, stack.ranges[#stack.ranges])
	if not r then
		return
	end

	select_range(buf, r)
	table.insert(stack.ranges, visual_range(buf))
end

---Shrink the visual selection back to the previous selection.
function M.shrink()
	local buf = api.nvim_get_current_buf()
	local stack = get_valid_stack(buf)
	if not stack or #stack.ranges < 2 then
		return
	end

	table.remove(stack.ranges)
	select_range(buf, stack.ranges[#stack.ranges])
end

---`<C-Space>` in normal mode
---@return string
function M.start_expr()
	if not get_node(api.nvim_get_current_buf()) then
		return ''
	end
	return ('<Cmd>lua %s.start()<CR>'):format(MODULE)
end

---`<C-Space>` in visual mode
---@return string
function M.expand_expr()
	if not get_parser(api.nvim_get_current_buf()) then
		return ''
	end
	return ('<Cmd>lua %s.expand()<CR>'):format(MODULE)
end

---`<BS>` in visual mode
---@return string
function M.shrink_expr()
	local buf = api.nvim_get_current_buf()
	-- Nothing of ours to shrink, keep the default `<BS>`
	if not get_parser(buf) or not get_valid_stack(buf) then
		return '<BS>'
	end
	return ('<Cmd>lua %s.shrink()<CR>'):format(MODULE)
end

return M
