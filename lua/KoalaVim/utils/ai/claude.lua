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

--- Sidekick tool config for `cswap`: claude run through cswap (claude account switcher)
--- as `cswap run [account] -- <claude params>`. Reuses sidekick's claude tool config.
---@return sidekick.cli.Config
function M.cswap_tool()
	local base = vim.api.nvim_get_runtime_file('sk/cli/claude.lua', false)[1]
	local config = base and dofile(base) or {}

	local conf = require('KoalaVim').conf
	local account = conf and conf.ai and conf.ai.cswap and conf.ai.cswap.account

	config.cmd = { 'cswap', 'run' }
	-- No account: cswap picks the current dir's mapped account
	if account and account ~= vim.NIL then
		table.insert(config.cmd, tostring(account))
	end
	table.insert(config.cmd, '--')
	config.is_proc = '\\<cswap\\>.*\\<run\\>'
	config.url = 'https://github.com/realiti4/claude-swap'
	return config
end

return M
