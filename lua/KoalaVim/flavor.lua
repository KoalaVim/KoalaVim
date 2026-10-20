-- Global flavor (`koala` | `lazyvim`), set with the `flavor` key in kvim.conf.
-- Read once, changing it requires a restart.
local M = {}

local DEFAULT = 'koala'
local VALID = { koala = true, lazyvim = true }

local flavor = nil ---@type 'koala'|'lazyvim'?

---@return 'koala'|'lazyvim'
function M.get()
	if flavor then
		return flavor
	end

	local conf = require('KoalaVim').conf
	if vim.tbl_isempty(conf) then
		-- conf isn't loaded yet, don't cache
		return DEFAULT
	end

	local value = conf.flavor
	if value == nil or value == vim.NIL then
		value = DEFAULT
	elseif not VALID[value] then
		local msg = 'Invalid flavor `%s` in kvim.conf (expected `koala` or `lazyvim`), using `%s`'
		require('KoalaVim.health').warn(msg:format(vim.inspect(value), DEFAULT))
		value = DEFAULT
	end

	flavor = value
	return flavor
end

---@param name 'koala'|'lazyvim'
---@return boolean
function M.is(name)
	return M.get() == name
end

-- Pick a value per flavor, e.g. `flavor.pick({ koala = 'a', lazyvim = 'b' })`
---@generic T
---@param tbl { koala: T, lazyvim: T }
---@return T
function M.pick(tbl)
	return tbl[M.get()]
end

return M
