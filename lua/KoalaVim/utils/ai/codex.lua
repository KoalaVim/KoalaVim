local M = {}

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

	-- Find the end of the prompt. codex's composer pads every line it owns (input
	-- lines, in-prompt blanks, the blank padding, and the footer/status line) with
	-- at least a space, while the unused terminal rows below are truly empty ("").
	-- So the footer is the bottom-most non-empty line, and everything above it down
	-- to the marker is prompt content (blank lines included). We deliberately don't
	-- match the footer's text, since that can change.
	local prompt_end = prompt_start
	for i = #lines, prompt_start + 1, -1 do
		if #lines[i] > 0 then
			prompt_end = i - 1 -- exclude the footer line itself
			break
		end
	end

	-- Keep the first line always (even if empty) so leading/embedded blanks are
	-- preserved; trailing blanks are trimmed below.
	local prompt_lines = { first }
	for i = prompt_start + 1, prompt_end do
		-- Continuation lines are rendered two columns in.
		local content = lines[i]:sub(3):gsub('%s+$', '')
		table.insert(prompt_lines, content)
	end

	while #prompt_lines > 0 and prompt_lines[#prompt_lines]:match('^%s*$') do
		table.remove(prompt_lines)
	end

	return prompt_lines
end

return M
