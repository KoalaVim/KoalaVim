local M = {}

--- @param name string
--- @param desc string
--- @param callback string|fun(args: vim.api.keyset.create_user_command.command_args) Replacement command to execute when this user command is executed. When called
--- from Lua, the command can also be a Lua function. The function is called with a
--- single table argument that contains the following keys:
--- - name: (string) Command name
--- - args: (string) The args passed to the command, if any [<args>]
--- - fargs: (table) The args split by unescaped whitespace (when more than one
--- argument is allowed), if any [<f-args>]
--- - nargs: (string) Number of arguments `:command-nargs`
--- - bang: (boolean) "true" if the command was executed with a ! modifier [<bang>]
--- - line1: (number) The starting line of the command range [<line1>]
--- - line2: (number) The final line of the command range [<line2>]
--- - range: (number) The number of items in the command range: 0, 1, or 2 [<range>]
--- - count: (number) Any count supplied [<count>]
--- - reg: (string) The optional register, if specified [<reg>]
--- - mods: (string) Command modifiers, if any [<mods>]
--- - smods: (table) Command modifiers in a structured format. Has the same
--- structure as the "mods" key of `nvim_parse_cmd()`.
--- @param opts? table<string, any>
function M.create(name, desc, callback, opts)
	opts = opts or {}
	opts.desc = desc
	vim.api.nvim_create_user_command(name, callback, opts)
end

return M
