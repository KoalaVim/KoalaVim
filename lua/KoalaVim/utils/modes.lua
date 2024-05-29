local M = {}

local health = require('KoalaVim.health')

function M.load(mode, args)
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
end

local function git_tree_mode(args)
	vim.cmd('Flog -- ' .. args)
end

M._modes = {
	git = git_mode,
	git_tree = git_tree_mode,
}

return M
