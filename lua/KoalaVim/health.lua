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

--- `:checkhealth KoalaVim`
function M.check()
	local flavor = require('KoalaVim.flavor')
	vim.health.start('KoalaVim')
	vim.health.info('flavor: ' .. flavor.get())

	vim.health.start('KoalaVim keymaps')
	-- All listed buffers that have their own keymaps (LSP, gitsigns) next to the global ones
	local bufnrs = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' and vim.bo[buf].filetype ~= '' then
			table.insert(bufnrs, buf)
		end
	end

	local ok, violations = pcall(require('KoalaVim.keymaps').check, { bufnrs = bufnrs })
	if not ok then
		vim.health.error('keymap check failed: ' .. tostring(violations))
		return
	end

	if #violations == 0 then
		vim.health.ok('no ambiguous leader prefixes, every contested key resolves to the ' .. flavor.get() .. ' flavor')
		return
	end
	for _, v in ipairs(violations) do
		vim.health.warn(('[%s] %s'):format(v.kind, v.msg))
	end
end

return M
