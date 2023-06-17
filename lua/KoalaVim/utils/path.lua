local M = {}

local IS_WIN32 = vim.fn.has('win32') == 1

-- thx for rmagatti/auto-session for those very helpful functions
function M.win32_unescaped_dir(dir)
	dir = dir:gsub(':', '++')
	if not vim.o.shellslash then
		dir = dir:gsub('\\', '\\%%')
		dir = dir:gsub('/', '\\%%')
	end

	return dir
end

function M.win32_escaped_dir(dir)
	dir = dir:gsub('++', ':')
	if not vim.o.shellslash then
		dir = dir:gsub('%%', '\\')
	end

	return dir
end

function M.unescape_dir(dir)
	return IS_WIN32 and M.win32_unescaped_dir(dir) or dir:gsub('\\%%', '/')
end

function M.escape_dir(dir)
	return IS_WIN32 and M.win32_escaped_dir(dir) or dir:gsub('/', '\\%%')
end

function M.escaped_session_name_from_cwd()
	return IS_WIN32 and M.unescape_dir(vim.fn.getcwd()) or M.escape_dir(vim.fn.getcwd())
end

return M
