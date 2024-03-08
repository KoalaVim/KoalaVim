local M = {}

local health = require('KoalaVim.health')

local function _create_default_file(file, default_content)
	vim.fn.mkdir(vim.fs.dirname(file), 'p')

	local f = io.open(file, 'w')
	if f == nil then
		health.warn(string.format('Failed to create default file at ' .. file))
		return
	end

	local str_content = '{}'
	if not vim.tbl_isempty(default_content) then
		local ok, res = pcall(vim.json.encode, default_content)
		if not ok or not res then
			health.warn(string.format('Failed to encode default file `%s` err: `%s`', file, res))
			vim.print(default_content)
			return
		end
		str_content = res
	end
	f:write(str_content)
	f:close()
end

function M.load(file, create_if_not_exist, default_content)
	local content = default_content or {}
	if file == nil then
		return content
	end

	local f = io.open(file, 'r')

	if f == nil then
		if create_if_not_exist then
			-- Create default file and assign default content
			_create_default_file(file, default_content or {})
		end

		return content
	end

	-- Read content from existing file
	local str_content = f:read('*all')
	f:close()

	-- Decode content to table
	local ok, res, a = pcall(vim.json.decode, str_content, {})
	if not ok then
		health.warn(string.format('Failed to decode `%s` err: `%s`', file, res))
		return content
	end

	return res
end

function M.save(file, content, dont_try_create_dir)
	if file == nil then
		return
	end

	local f = io.open(file, 'w')

	if f == nil then
		if not dont_try_create_dir then
			-- Try again after creating parent dir
			vim.fn.mkdir(vim.fs.dirname(file), 'p')
			return M.save(file, content, dont_try_create_dir)
		end
		health.warn(string.format('Failed to create file at ' .. file))
		return
	end

	-- Encode content to json
	local ok, res = pcall(vim.json.encode, content)
	if not ok then
		health.warn(string.format('Failed to encode `%s` err: `%s`', file, res))
		vim.print(content)
		return
	end

	f:write(res)
	f:close()
end

-- Doesn't override current file
function M.create_default(file, default_content)
	local f = io.open(file, 'r')
	if f == nil then
		_create_default_file(file, default_content)
		return
	end
	f:close()
end

return M
