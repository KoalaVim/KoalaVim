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
	vim.cmd('Flog -- ' .. args)
	vim.cmd('G')
	vim.cmd('1tabclose')
end

local function git_tree_mode(args)
	vim.cmd('Flog -- ' .. args)
	vim.cmd('1tabclose')
end

M._modes = {
	git = git_mode,
	git_tree = git_tree_mode,
}

return M
