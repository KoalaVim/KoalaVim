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

return M
