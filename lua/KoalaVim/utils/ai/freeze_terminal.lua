local M = {}

---@type { win: integer, term_buf: integer, scratch_buf: integer }?
local frozen = nil

--- Snapshot the terminal into a read-only scratch buffer. The full scrollback
--- text is copied from the terminal buffer (cheap: a single nvim_buf_get_lines),
--- while the visible screen region is captured cell-by-cell with extmarks that
--- reproduce the terminal colors (uses the internal nvim__inspect_cell API for
--- accurate RGB extraction). Terminal colors aren't exposed for off-screen lines,
--- so scrollback above/below the visible region is plain text.
---@param win integer
---@param term_buf integer
function M.freeze(win, term_buf)
	if frozen then
		return
	end

	local pos = vim.api.nvim_win_get_position(win)
	local width = vim.api.nvim_win_get_width(win)
	local topline, botline = unpack(vim.api.nvim_win_call(win, function()
		return { vim.fn.line('w0'), vim.fn.line('w$') }
	end))
	-- Only screen rows backed by buffer lines (skip end-of-buffer filler rows)
	local height = math.min(vim.api.nvim_win_get_height(win), botline - topline + 1)
	local row_offset = topline - 1 -- buffer row (0-based) of screen row 0
	local sr = pos[1] + 1 -- screenstring/screenattr are 1-based
	local sc = pos[2] + 1

	local lines = {}
	local hl_runs = {} -- { row, byte_start, byte_end, hl_group_name }
	local ns = vim.api.nvim_create_namespace('frozen_terminal')
	local hl_cache = {} -- screenattr value → hl_group name
	local hl_counter = 0

	for r = 0, height - 1 do
		local parts = {}
		local byte_pos = {}
		local offset = 0
		local cur_attr, run_start_byte

		for c = 0, width - 1 do
			byte_pos[c] = offset
			local ch = vim.fn.screenstring(sr + r, sc + c)
			if ch == '' then
				ch = ' '
			end
			parts[#parts + 1] = ch
			offset = offset + #ch

			local attr = vim.fn.screenattr(sr + r, sc + c)
			if attr ~= cur_attr then
				if cur_attr and cur_attr ~= 0 and hl_cache[cur_attr] then
					hl_runs[#hl_runs + 1] = { row_offset + r, run_start_byte, byte_pos[c], hl_cache[cur_attr] }
				end
				if attr ~= 0 and not hl_cache[attr] then
					local ok, cell = pcall(vim.api.nvim__inspect_cell, 1, pos[1] + r, pos[2] + c)
					if ok and cell and cell[2] then
						local a = cell[2]
						local hl = {}
						if a.foreground then
							hl.fg = a.foreground
						end
						if a.background then
							hl.bg = a.background
						end
						if a.bold then
							hl.bold = true
						end
						if a.italic then
							hl.italic = true
						end
						if a.underline then
							hl.underline = true
						end
						if a.reverse then
							hl.reverse = true
						end
						if a.strikethrough then
							hl.strikethrough = true
						end
						if next(hl) then
							hl_counter = hl_counter + 1
							local name = 'FrozenTerm' .. hl_counter
							vim.api.nvim_set_hl(0, name, hl)
							hl_cache[attr] = name
						end
					end
				end
				cur_attr = attr
				run_start_byte = byte_pos[c]
			end
		end
		byte_pos[width] = offset
		if cur_attr and cur_attr ~= 0 and hl_cache[cur_attr] then
			hl_runs[#hl_runs + 1] = { row_offset + r, run_start_byte, byte_pos[width], hl_cache[cur_attr] }
		end

		lines[#lines + 1] = table.concat(parts)
	end

	-- Splice the colored screen capture between the plain-text scrollback
	-- above and any lines below the window (if the user had scrolled up).
	local above = vim.api.nvim_buf_get_lines(term_buf, 0, row_offset, false)
	local below = vim.api.nvim_buf_get_lines(term_buf, row_offset + height, -1, false)

	local all = vim.list_extend(vim.list_extend(above, lines), below)

	local scratch = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(scratch, 0, -1, false, all)

	for _, run in ipairs(hl_runs) do
		pcall(vim.api.nvim_buf_set_extmark, scratch, ns, run[1], run[2], {
			end_col = run[3],
			hl_group = run[4],
		})
	end

	vim.bo[scratch].modifiable = false
	vim.api.nvim_win_set_buf(win, scratch)
	-- Land on the last non-blank line of the previously visible region
	local last_content = row_offset + 1
	for i, line in ipairs(lines) do
		if line:match('%S') then
			last_content = row_offset + i
		end
	end
	vim.api.nvim_win_set_cursor(win, { last_content, 0 })
	vim.defer_fn(function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_call(win, function()
				vim.cmd('normal! zb')
			end)
		end
	end, 100)
	frozen = {
		win = win,
		term_buf = term_buf,
		scratch_buf = scratch,
	}
end

--- Restore the real terminal buffer in the window and clean up the snapshot.
function M.unfreeze()
	if not frozen then
		return
	end
	local f = frozen
	frozen = nil
	if vim.api.nvim_win_is_valid(f.win) and vim.api.nvim_buf_is_valid(f.term_buf) then
		vim.api.nvim_win_set_buf(f.win, f.term_buf)
	end
	if vim.api.nvim_buf_is_valid(f.scratch_buf) then
		pcall(vim.api.nvim_buf_delete, f.scratch_buf, { force = true })
	end
end

---@return boolean
function M.is_frozen()
	return frozen ~= nil
end

return M
