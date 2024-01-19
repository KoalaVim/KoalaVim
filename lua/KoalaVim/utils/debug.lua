local M = {}

local lastDebuggedFile = nil
local lastDebuggedArgs = nil

function M._get_last_debugged_file(default)
	return lastDebuggedFile or default
end

function M.choose_file()
	---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
	lastDebuggedFile = vim.fn.input('Path to executable: ', M._get_last_debugged_file('./a.out'), 'file')
	return lastDebuggedFile
end

function M.choose_args()
	---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
	lastDebuggedArgs = vim.fn.input('Enter arguments to run the program with: ', lastDebuggedArgs or '', 'file')
	return vim.split(lastDebuggedArgs, ' ', { trimempty = true })
end

function M.get_session_data()
	return {
		lastDebuggedFile = lastDebuggedFile,
		lastDebuggedArgs = lastDebuggedArgs,
	}
end

function M.restore_session_data(data)
	lastDebuggedFile = data.lastDebuggedFile
	lastDebuggedArgs = data.lastDebuggedArgs
end

return M
