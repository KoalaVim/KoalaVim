local M = {}

function M.restore_logged(opts)
	local res = require('lazy').restore(opts)
	res:wait()

	local plugins = res['_plugins']
	local ret = { plugins = {} }

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
