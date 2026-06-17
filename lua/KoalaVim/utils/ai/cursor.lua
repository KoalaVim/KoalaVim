local M = {}

local IGNORE_PREFIXES = {
	'Add a follow-up',
	'Plan, search, build anything',
	'Describe how to revise the plan',
}

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

	if prompt_lines[1] then
		for _, prefix in ipairs(IGNORE_PREFIXES) do
			if prompt_lines[1]:sub(1, #prefix) == prefix then
				return {}
			end
		end
	end

	return prompt_lines
end

local QUESTION_HINT = '↑/↓ option'

---@param prompt_lines string[]
function M.is_question_tui(prompt_lines)
	local last = prompt_lines[#prompt_lines]
	return last ~= nil and last:find(QUESTION_HINT, 1, true) ~= nil
end

---@param prompt_lines string[]
function M.get_question_prompt(prompt_lines)
	local result = {}
	local collecting = false

	for _, line in ipairs(prompt_lines) do
		if line:find(QUESTION_HINT, 1, true) then
			break
		end

		local text = line:match('%[.%]%s.-%:%s*(.*)')
		if text then
			collecting = true
			result = {}
			if text ~= '' then
				table.insert(result, text)
			end
		elseif collecting then
			if line:match('%[.%]') then
				if #result > 0 then
					break
				end
				collecting = false
			else
				table.insert(result, line)
			end
		end
	end

	return result
end

return M
