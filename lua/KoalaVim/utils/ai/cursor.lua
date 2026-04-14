local M = {}

function M.get_prompt()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Find the last prompt box (bottom-up search)
	-- Old format: ┌─ / │ / └─
	-- New format: ▄▄▄ / prompt text / ▀▀▀
	local box_start, box_end
	for i = #lines, 1, -1 do
		if not box_end and (lines[i]:match('└─') or lines[i]:match('▀▀')) then
			box_end = i
		elseif box_end and (lines[i]:match('┌─') or lines[i]:match('▄▄')) then
			box_start = i
			break
		end
	end

	if not box_start or not box_end then
		return {}
	end

	local prompt_lines = {}

	for i = box_start + 1, box_end - 1 do
		-- Old format: │content│
		local content = lines[i]:match('│(.*)│%s*$')
		if not content then
			-- New format: raw line with optional → prefix
			content = lines[i]
		end
		if content then
			content = content:gsub('→%s?', '')
			content = vim.trim(content)
			if content ~= '' then
				table.insert(prompt_lines, content)
			end
		end
	end

	return prompt_lines
end

return M
