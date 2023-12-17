local M = {}

local lastDebuggedFile = nil

function M._get_last_debugged_file(default)
	return lastDebuggedFile or default
end

function M.choose_file()
	---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
	lastDebuggedFile = vim.fn.input('Path to executable: ', M._get_last_debugged_file('./a.out'), 'file')
	return lastDebuggedFile
end

function M.get_session_data()
	return {
		lastDebuggedFile = lastDebuggedFile,
	}
end

function M.restore_session_data(data)
	lastDebuggedFile = data.lastDebuggedFile
end

return M
