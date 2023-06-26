local M = {}

local deployedTerminal = nil
local deployDir = nil

function M.reset_deploy(dir)
	if dir == nil then
		dir = vim.fn.expand('%:p:h')
	end
	deployedTerminal = require('toggleterm.terminal').Terminal:new({ cmd = 'deploy', dir = dir })
	deployDir = dir
end

function M.deploy()
	if deployedTerminal == nil then
		M.reset_deploy(deployDir)
	end
	---@diagnostic disable-next-line: need-check-nil
	deployedTerminal:toggle()
end

function M.get_session_data()
	return {
		dir = deployDir,
	}
end

function M.restore_session_data(data)
	deployDir = data.dir
end

return M
