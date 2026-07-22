local M = {}

local health = require('KoalaVim.health')

function M.load(mode, args)
	args = args or ''
	if not M._modes[mode] then
		health.error(string.format("Failed to load `%s` mode (doesn't exists)", mode))
		return
	end

	-- Load mode
	return M._modes[mode](args)
end

local function git_mode(args)
	require('KoalaVim.utils.git').show_tree(args)
	require('KoalaVim.utils.git').show_status()
end

local function git_tree_mode(args)
	require('KoalaVim.utils.git').show_tree(args)
end

local function git_diff_mode(args)
	require('KoalaVim.utils.git').show_diff(args)

	vim.schedule(function()
		vim.cmd('tabonly') -- Close other tab pages
	end)
end

local function ai_mode(args)
	vim.api.nvim_create_autocmd('FileType', {
		pattern = 'sidekick_terminal',
		once = true,
		callback = function()
			vim.defer_fn(function()
				require('KoalaVim.utils.ai.general').zoom_sidekick()
			end, 200)
		end,
	})

	local parts = vim.split(vim.trim(args or ''), '%s+', { trimempty = true })
	local tool = table.remove(parts, 1)
	if tool and tool ~= '' then
		require('KoalaVim.utils.ai.general').set_default_tool(tool)

		if not vim.tbl_isempty(parts) then
			local config = require('sidekick.config')
			local tool_config = config.cli.tools[tool]
			if not tool_config then
				health.error(('Unknown Sidekick tool `%s`'):format(tool))
				return
			end

			local cmd = vim.deepcopy(config.get_tool(tool).cmd)
			vim.list_extend(cmd, parts)
			tool_config.cmd = cmd
		end
	end

	require('KoalaVim.utils.ai.general').with_default_tool(require('sidekick.cli').show)
end

M._modes = {
	git = git_mode,
	git_tree = git_tree_mode,
	git_diff = git_diff_mode,
	ai = ai_mode,
}

return M
