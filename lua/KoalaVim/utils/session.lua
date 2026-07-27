local M = {}

function M.cwd_session()
	return require('KoalaVim.utils.path').escaped_session_name_from_cwd()
end

function M.load_cwd_session()
	local cwd_session = M.cwd_session()
	if not require('possession.session').exists(cwd_session) then
		vim.notify("Session doesn't exist!")
		return
	end
	require('possession.session').load(cwd_session)
	KoalaEnableSession()
end

local path_utils = require('KoalaVim.utils.path')

function M.list_sessions()
	local home_dir_regex = '^' .. vim.loop.os_homedir()
	local sessions = require('possession.query').as_list()

	local items = {}
	for _, entry in ipairs(sessions) do
		local display = path_utils.unescape_dir(entry.name):gsub(home_dir_regex, '~')
		table.insert(items, { text = display, name = entry.name })
	end

	Snacks.picker({
		title = 'Choose Session (sorted by frequency)',
		items = items,
		format = function(item)
			return { { item.text } }
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				require('possession.session').load(item.name)
			end
		end,
		layout = {
			preset = 'select',
		},
	})
end

return M
