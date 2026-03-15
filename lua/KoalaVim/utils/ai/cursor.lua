local M = {}

-- FIXME: only for cursor
function M.get_prompt()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Find the last box (bottom-up search)
	local box_start, box_end
	for i = #lines, 1, -1 do
		if not box_end and lines[i]:match('└─') then
			box_end = i
		elseif box_end and lines[i]:match('┌─') then
			box_start = i
			break
		end
	end

	if not box_start or not box_end then
		return ''
	end

	local prompt_lines = {}

	for i = box_start + 1, box_end - 1 do
		local content = lines[i]:match('│(.*)│%s*$')
		if content then
			content = content:gsub('→%s?', '')
			table.insert(prompt_lines, vim.trim(content))
		end
	end

	return prompt_lines
end

return M
