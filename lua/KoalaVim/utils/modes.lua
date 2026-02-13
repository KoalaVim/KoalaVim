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
	vim.cmd('DiffviewOpen')

	vim.schedule(function ()
		vim.cmd('tabonly') -- Close other tab pages
	end)
end

M._modes = {
	git = git_mode,
	git_tree = git_tree_mode,
	git_diff = git_diff_mode,
}

return M
