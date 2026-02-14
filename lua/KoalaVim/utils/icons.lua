local M = {}

M.severity_to_name = {
	[vim.diagnostic.severity.ERROR] = 'error',
	[vim.diagnostic.severity.WARN] = 'warn',
	[vim.diagnostic.severity.HINT] = 'hint',
	[vim.diagnostic.severity.INFO] = 'info',
}

M.diagnostics = {
	error = '',
	warn = '⚠ ',
	hint = '',
	info = '',
}

function M.pad_right(icons, padding)
	local icons_padded = {}
	for key, icon in pairs(icons) do
		-- Remove existing padding and re-pad
		icons_padded[key] = icon:gsub('%s+', '') .. padding
	end

	return icons_padded
end

return M
