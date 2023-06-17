local M = {}

M.NO_DEFAULT = 'KoalaOpts_NoDefault'

-- TODO: type hint options system
-- TODO: export/import options to json
-- TODO: auto doc
M.default_opts = {
	warnings = true, -- Warn on missing options
	autocmds = {
		half_screen = {
			-- type: number
			-- Amount of columns when using full screen (use `echo $COLUMNS`)
			full_screen_width = M.NO_DEFAULT,
		},
	},
	plugins = {
		open_jira = {
			jira_url = M.NO_DEFAULT,
		},
	},
}

local function _verify(opts_tbl, scope_string)
	local valid = true
	for key, value in pairs(opts_tbl) do
		if type(value) == 'table' then
			_verify(value, scope_string and scope_string .. key .. '.' or nil)
		else
			if value == M.NO_DEFAULT then
				if scope_string then
					-- TODO: better warnings
					-- stylua: ignore
					print(scope_string .. key .. " isn't configured (you can turn off this message by passing `warnings = false` in koala opts)")
					valid = false
				else
					-- If warnings aren't on just return
					return false
				end
			end
		end
	end

	return valid
end

function M.verify(opts_tbl)
	return _verify(opts_tbl, nil)
end

function M.load_opts(opts)
	opts = opts or {}
	opts = vim.tbl_deep_extend('keep', opts, M.default_opts)

	if opts.warnings then
		_verify(opts, '')
	end
	require('KoalaVim').opts = opts
end

return M
