-- State
local M = {}

local json_file = require('KoalaVim.utils.json_file')

local function _get_koala_data_path()
	return vim.fn.stdpath('data') .. '/koala'
end

local function _get_kvim_state_file()
	return _get_koala_data_path() .. '/kvim_state.json'
end

function M.save()
	-- TODO: lockfile
	json_file.save(_get_kvim_state_file(), require('KoalaVim').state)
end

function M.load()
	require('KoalaVim').state = json_file.load(_get_kvim_state_file())
end

return M
