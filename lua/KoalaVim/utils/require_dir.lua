-- Require all other `.lua` files in the same directory
-- Credit: https://github.com/hallettj/dot-vim

-- TODO: remove binary dependency
local M = {}

local function scandir(directory, recursive)
	local i, t, popen = 0, {}, io.popen
	local pfile = nil

	if recursive then
		pfile = popen('fd . --base-directory="' .. directory .. '"')
	else
		pfile = popen('ls -a "' .. directory .. '"')
	end
	-- print(directory)

	if pfile == nil then
		return {}
	end

	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename
	end
	pfile:close()
	return t
end

local function get_config_files(dir, recursive)
	return vim.tbl_filter(function(filename)
		local is_lua_module = string.match(filename, '[.]lua$')
		return is_lua_module
	end, scandir(dir, recursive))
end

local function _get_current_dir()
	local info = debug.getinfo(3, 'S')
	return string.match(info.source, '^@(.*)/') .. '/'
end

local function _require(relative_dir, recursive, require_prefix)
	local current_dir = _get_current_dir()
	local ret_vals = {}
	local full_dir = current_dir .. relative_dir .. '/'

	for _, filename in ipairs(get_config_files(full_dir, recursive)) do
		local config_module = string.match(filename, '(.+).lua$')
		-- print('require', require_prefix .. '.' .. relative_dir .. '.' .. config_module)
		table.insert(ret_vals, require(require_prefix .. '.' .. relative_dir .. '.' .. config_module))
	end

	return ret_vals
end

function M.require(relative_dir, require_prefix)
	return _require(relative_dir, false, require_prefix)
end

function M.recursive_require(relative_dir, require_prefix)
	return _require(relative_dir, true, require_prefix)
end

return M
