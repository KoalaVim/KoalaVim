local M = {}

local wrapped = false

-- Routes LazyVim's picker requests (`LazyVim.pick`) to fff for file/text search, the rest stays on snacks
-- `LazyVim.pick.picker` is registered by the `editor.snacks_picker` extra, call after it's imported.
function M.setup()
	local picker = _G.LazyVim and LazyVim.pick.picker
	if wrapped then
		return true
	end
	if not picker then
		return false
	end
	wrapped = true

	local snacks_open = picker.open
	---@param command string
	---@param opts? lazyvim.util.pick.Opts
	picker.open = function(command, opts)
		opts = opts or {}
		-- `LazyVim.pick` sets `opts.cwd` to the root dir unless `opts.root == false`
		if command == 'files' then
			if opts.cwd then
				require('fff').find_files_in_dir(opts.cwd)
			else
				require('fff').find_files()
			end
		elseif command == 'grep' or command == 'live_grep' then
			require('fff').live_grep({ cwd = opts.cwd })
		else
			snacks_open(command, opts)
		end
	end
	return true
end

return M
