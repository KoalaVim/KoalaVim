local M = {}

local fidget = require('fidget')

local function _log(msg, level, ttl)
	fidget.notify(msg, level, {
		group = 'KoalaHealth',
		ttl = ttl,
	})
end

function M.warn(msg)
	_log(msg, vim.log.levels.WARN, 25)
end

function M.error(msg)
	_log(msg, vim.log.levels.ERROR, math.huge)
end

return M
