local M = {}

local api = vim.api

function M.get_all_non_floating_wins()
	local non_floating_wins = {}

	for _, winid in ipairs(api.nvim_list_wins()) do
		local is_floating = api.nvim_win_get_config(winid).relative ~= ''
		if not is_floating then
			table.insert(non_floating_wins, winid)
		end
	end
	return non_floating_wins
end

function M.find_win_by_buf(buf)
	local win_ids = api.nvim_tabpage_list_wins(api.nvim_get_current_tabpage())
	for _, win_id in ipairs(win_ids) do
		if buf == api.nvim_win_get_buf(win_id) then
			return win_id
		end
	end
	return nil
end

function M.find_win_by_ft(ft)
	local win_ids = api.nvim_tabpage_list_wins(api.nvim_get_current_tabpage())
	for _, win_id in ipairs(win_ids) do
		if vim.bo[api.nvim_win_get_buf(win_id)].filetype == ft then
			return win_id
		end
	end
	return nil
end

function M.set_option(win, k, v)
	if vim.api.nvim_set_option_value then
		vim.api.nvim_set_option_value(k, v, { scope = 'local', win = win })
	else
		vim.wo[win][k] = v
	end
end

return M
