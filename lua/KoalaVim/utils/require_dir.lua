-- Require all other `.lua` files in the same directory
-- Credit: https://github.com/hallettj/dot-vim

local M = {}

-- Returns the sorted `.lua` files (relative to `directory`) under `directory`
local function get_config_files(directory, recursive)
	local files = {}
	if vim.fn.isdirectory(directory) == 0 then
		return files
	end

	for name, type in vim.fs.dir(directory, { depth = recursive and math.huge or 1 }) do
		if (type == 'file' or type == 'link') and name:match('[.]lua$') then
			table.insert(files, name)
		end
	end

	table.sort(files)
	return files
end

local function _get_current_dir()
	local info = debug.getinfo(3, 'S')
	return string.match(info.source, '^@(.*)[/\\]') .. '/'
end

-- Require every `.lua` file under the absolute path `dir`.
-- Module names are `module_prefix` followed by the file's relative path (`/` -> `.`).
-- opts.recursive: also require files from sub directories
-- opts.skip: function(relative_module) -> boolean, return true to not require that module
function M.require_abs(dir, module_prefix, opts)
	opts = opts or {}
	local ret_vals = {}

	for _, filename in ipairs(get_config_files(dir, opts.recursive)) do
		local relative_module = string.match(filename, '(.+).lua$')
		if not (opts.skip and opts.skip(relative_module)) then
			table.insert(ret_vals, require(module_prefix .. '.' .. relative_module:gsub('/', '.')))
		end
	end

	return ret_vals
end

local function _require(relative_dir, recursive, require_prefix)
	local current_dir = _get_current_dir()
	if require_prefix == nil then
		current_dir = current_dir .. 'lua/'
	end
	local module_prefix = (require_prefix and require_prefix .. '.' or '') .. relative_dir

	return M.require_abs(current_dir .. relative_dir .. '/', module_prefix, { recursive = recursive })
end

-- TODO: doc.
-- pass require_prefix as nil to require from user config dir
function M.require(relative_dir, require_prefix)
	return _require(relative_dir, false, require_prefix)
end

function M.recursive_require(relative_dir, require_prefix)
	return _require(relative_dir, true, require_prefix)
end

return M
