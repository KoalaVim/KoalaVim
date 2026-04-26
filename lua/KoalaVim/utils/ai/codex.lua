local M = {}

local function is_status_line(line)
	local trimmed = vim.trim(line)

	return trimmed:find('Context', 1, true) and trimmed:match('^gpt[%w%._%-]*%s')
end

function M.get_prompt()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local prompt_start
	for i = #lines, 1, -1 do
		if lines[i]:match('^%s*›') then
			prompt_start = i
			break
		end
	end

	if not prompt_start then
		return {}
	end

	local raw = lines[prompt_start]
	local prompt_col = raw:find('›', 1, true)
	local after = prompt_col and raw:sub(prompt_col + #'›') or ''
	local first = vim.trim(after)

	local prompt_lines = {}
	if first ~= '' then
		table.insert(prompt_lines, first)
	end

	for i = prompt_start + 1, #lines do
		local line = lines[i]
		local trimmed = vim.trim(line)

		if trimmed == '' or is_status_line(line) then
			break
		end

		-- Wrapped prompt lines are rendered two columns in, below the input text.
		local content = line:sub(1, 2) == '  ' and line:sub(3) or trimmed
		content = content:gsub('%s+$', '')
		if content ~= '' then
			table.insert(prompt_lines, content)
		end
	end

	while #prompt_lines > 0 and prompt_lines[#prompt_lines]:match('^%s*$') do
		table.remove(prompt_lines)
	end

	return prompt_lines
end

return M
