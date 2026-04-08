local M = {}

function M.restore_logged(opts)
	opts = opts or {}
	-- Exclude KoalaVim from restore to avoid resetting it mid-run
	opts.plugins = vim.tbl_filter(function(plugin)
		return plugin.name ~= 'KoalaVim'
	end, require('lazy').plugins())

	local res = require('lazy').restore(opts)
	res:wait()

	local plugins = res['_plugins']
	local ret = { plugins = vim.empty_dict() }

	for _, plugin in ipairs(plugins) do
		local tasks = plugin['_']['tasks']
		for _, task in ipairs(tasks) do
			if task.error then
				ret.plugins[plugin[1]] = task.error
			end
		end
	end

	return ret
end

return M
