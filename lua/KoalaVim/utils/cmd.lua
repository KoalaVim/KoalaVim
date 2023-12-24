local M = {}

--- @param name string
--- @param desc string
--- @param callback object
--- @param opts? table<string, any>
function M.create(name, desc, callback, opts)
	opts = opts or {}
	opts.desc = desc
	vim.api.nvim_create_user_command(name, callback, opts)
end

return M
