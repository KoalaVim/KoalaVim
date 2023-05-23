-- Verify half_screen options
local opts = require('KoalaVim').opts.autocmds.half_screen
if not require('KoalaVim.opts').verify(opts) then
	return
end

local api = vim.api

-- Switch layout when half screen
local ui = require('KoalaVim.utils.ui')
local function is_valid_win(winid)
	local floating = api.nvim_win_get_config(winid).relative ~= ''
	local ft = api.nvim_buf_get_option(api.nvim_win_get_buf(winid), 'filetype')

	-- TODO: More ignores
	return ft ~= 'NvimTree' and not floating
end

local function is_temp_win(winid)
	local ft = api.nvim_buf_get_option(api.nvim_win_get_buf(winid), 'filetype')

	-- TODO: delete more temp windows such as fugitive
	return ft == 'NvimTree'
end

-- Change split layout from 2 vertical to 2 horizontals, or otherwise
local function change_split_layout(vertical_to_horizontal)
	local anchor_index = 0
	local distance_index = 0
	local wincmd_dir = ''
	if vertical_to_horizontal then
		anchor_index = 1
		distance_index = 2
		wincmd_dir = 'J'
	else
		anchor_index = 2
		distance_index = 1
		wincmd_dir = 'L'
	end

	local win_ids = api.nvim_tabpage_list_wins(api.nvim_get_current_tabpage())
	local last_anchor = -1
	local counter = 0
	local farthest_win = -1
	local farthest_distance = -1

	for _, winid in ipairs(win_ids) do
		if is_valid_win(winid) then
			local pos = api.nvim_win_get_position(winid)
			local anchor = pos[anchor_index]
			if last_anchor ~= -1 and anchor ~= last_anchor then
				return -- Not in the same anchor (row/col), not a a valid layout
			end

			local distance = pos[distance_index]
			if distance > farthest_distance then
				farthest_win = winid
				farthest_distance = distance
			end

			last_anchor = anchor
			counter = counter + 1
			if counter > 2 then
				return -- More than two windows, not a valid layout
			end
		end
	end

	-- Didn't found windows
	if farthest_distance == -1 then
		return
	end

	if vertical_to_horizontal then
		-- Delete "temp" windows before slicing to half screen
		for _, winid in ipairs(win_ids) do
			if is_temp_win(winid) then
				api.nvim_win_close(winid, true)
			end
		end
	end

	local current_win = api.nvim_get_current_win()

	-- Move to the right/below window (farthest_win)
	api.nvim_set_current_win(farthest_win)
	vim.cmd('wincmd ' .. wincmd_dir)
	-- -- Move back to original window
	api.nvim_set_current_win(current_win)
end

local function set_half_layout()
	ui.setup_lualine(true)

	change_split_layout(true)
end

local function set_full_layout()
	ui.setup_lualine(false)

	change_split_layout(false)
end

local function is_half()
	return api.nvim_get_option_value('columns', {}) <= opts.full_screen_width / 2
end

local function set_layout()
	if is_half() then
		set_half_layout()
	else
		set_full_layout()
	end
end

local LAST_STATE = false
api.nvim_create_autocmd('VimEnter', {
	callback = function()
		LAST_STATE = is_half()
		set_layout()
	end,
})
api.nvim_create_autocmd('VimResized', {
	callback = function()
		local new_state = is_half()
		if LAST_STATE == new_state then
			return -- No need to do anything
		end
		set_layout()
		LAST_STATE = new_state
	end,
})
