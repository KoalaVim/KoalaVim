local M = {}

function M.get_prompt()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local prompt_start
	for i = #lines, 1, -1 do
		if lines[i]:match('❯') then
			prompt_start = i
			break
		end
	end

	if not prompt_start then
		return {}
	end

	-- First line: text after ❯ (skip non-breaking space U+00A0 = c2 a0)
	local raw = lines[prompt_start]
	local prompt_col = raw:find('❯')
	local after = prompt_col and raw:sub(prompt_col + #'❯') or ''
	after = after:gsub('^\xc2\xa0', '')
	local first = vim.trim(after)

	-- Find the end: the separator line (─────) marks the end of the prompt area
	local prompt_end = #lines
	for i = prompt_start + 1, #lines do
		if vim.startswith(lines[i], '─') then
			prompt_end = i - 1
			break
		end
	end

	local prompt_lines = { first }
	for i = prompt_start + 1, prompt_end do
		-- Continuation lines have 2-space prefix and trailing whitespace
		local line = lines[i]:sub(3):gsub('%s+$', '')
		table.insert(prompt_lines, line)
	end

	-- Trim trailing empty lines
	while #prompt_lines > 0 and prompt_lines[#prompt_lines]:match('^%s*$') do
		table.remove(prompt_lines)
	end

	return prompt_lines
end

return M
