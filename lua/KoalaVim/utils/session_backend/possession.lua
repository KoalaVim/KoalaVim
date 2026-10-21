-- Session backend for the `koala` flavor (jedrzejboczar/possession.nvim)
-- Sessions are stored by name, the cwd session is named after the escaped cwd.
local M = {}

local path_utils = require('KoalaVim.utils.path')

function M.exists_cwd()
	return require('possession.session').exists(require('KoalaVim.utils.session').cwd_session())
end

function M.save()
	require('possession.session').save(require('KoalaVim.utils.session').cwd_session(), { no_confirm = true })
end

function M.load_cwd()
	require('possession.session').load(require('KoalaVim.utils.session').cwd_session())
end

function M.delete_cwd()
	require('possession.session').delete(require('KoalaVim.utils.session').cwd_session(), {})
end

function M.list()
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

-- possession reads `KOALA_AUTOSAVE_SESSION` on every autosave, nothing to sync
function M.set_autosave(_) end

return M
