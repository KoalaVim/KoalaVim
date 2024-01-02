local M = {}

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
