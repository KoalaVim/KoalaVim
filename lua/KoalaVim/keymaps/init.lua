-- Flavor-aware keymaps: `contested` (data), `remap` (engine), `check` (verification).
-- KoalaVim's own keys use `kmap`/`kkeys`/`klhs` from `KoalaVim.utils.map`.
local M = {}

--- Verify the keymaps of the active flavor, see `KoalaVim.keymaps.check`.
--- Returns the violations (empty list: all good). Run it once everything is loaded (after `VeryLazy`).
---@param opts? KoalaVim.Keymaps.CheckOpts
---@return KoalaVim.Keymaps.Violation[]
function M.check(opts)
	return require('KoalaVim.keymaps.check').run(opts)
end

return M
