local M = {}

local fidget = require('fidget')

local function _log(msg, level, ttl, notify)
	fidget.notify(msg, level, {
		group = 'KoalaHealth',
		ttl = ttl,
	})

	if notify then
		vim.notify(msg, level, {})
	end
end

function M.warn(msg, notify)
	_log(msg, vim.log.levels.WARN, 25, notify)
end

function M.error(msg)
	_log(msg, vim.log.levels.ERROR, math.huge)
end

function M.info(msg, notify)
	_log(msg, vim.log.levels.INFO, 25, notify)
end

return M
