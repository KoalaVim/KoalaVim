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
}

function M.verify(opts_tbl, warn)
	local valid = true
	for key, value in pairs(opts_tbl) do
		if (type(value) == 'table') then
			M.verify(value)
		else
			if value == M.NO_DEFAULT then
				if warn then
					-- TODO: better warnings
					print(key ..
					" isn't configured (you can turn off this message by passing `warnings = false` in koala opts)")
				end
				valid = false
			end
		end
	end

	return valid
end

function M.load_opts(opts)
	opts = opts or {}
	opts = vim.tbl_deep_extend('keep', opts, M.default_opts)

	if opts.warnings then
		M.verify(opts, true)
	end
	require('KoalaVim').opts = opts
end

return M
