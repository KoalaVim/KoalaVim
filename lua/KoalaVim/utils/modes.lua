local M = {}

local health = require('KoalaVim.health')

function M.load(mode)
	if not M._modes[mode] then
		health.error(string.format("Failed to load `%s` mode (doesn't exists)", mode))
		return
	end

	-- Load mode
	return M._modes[mode]()
end

local function git_mode()
	vim.cmd([[Flogsplit
				wincmd k | q
				G]])
end

local function git_tree_mode()
	vim.cmd([[Flogsplit
			wincmd k | q]])
end

M._modes = {
	git = git_mode,
	git_tree = git_tree_mode,
}

return M
