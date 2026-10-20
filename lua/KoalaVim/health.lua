local M = {}

local function _log(msg, level, ttl, notify)
	-- fidget is a plugin, it isn't on the runtimepath before lazy.nvim setup (e.g. during `KoalaVim.init()`)
	local ok, fidget = pcall(require, 'fidget')
	if not ok then
		vim.notify(msg, level, {})
		return
	end

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
