-- Zellij multiplexer backend for Navigator.nvim.
--
-- Navigator runs `wincmd <dir>` first and only calls us once the cursor is
-- already at the edge of Neovim's layout, where we hand focus to the neighbouring
-- Zellij pane.
--
-- Requires Zellij to be in "locked" mode while nvim is focused (zellij-autolock
-- does this), otherwise Zellij keeps <C-hjkl> and none of this runs.

---@private
---@class KoalaZellij: Vi
---@field private directions table<Direction, string[]>
local Zellij = require('Navigator.mux.vi'):new()

-- `zellij action` argument lists per direction. Lists rather than fixed
-- {action, direction} pairs because `p` (NavigatorPrevious) takes no direction.
local directions = {
	h = { 'move-focus', 'left' },
	j = { 'move-focus', 'down' },
	k = { 'move-focus', 'up' },
	l = { 'move-focus', 'right' },
	p = { 'focus-previous-pane' },
}

---Creates a new Zellij navigator instance
---@return KoalaZellij
function Zellij:new()
	assert(vim.env.ZELLIJ ~= nil, '[Navigator] Zellij is not running!')

	self.__index = self
	return setmetatable({ directions = directions }, self)
end

---Switch pane in Zellij
---@param direction Direction See |navigator.api.Direction|
---@return KoalaZellij
function Zellij:navigate(direction)
	local args = self.directions[direction]
	if args == nil then
		return self
	end

	-- Fire and forget: nothing downstream waits on the focus change.
	vim.system({ 'zellij', 'action', unpack(args) }, { text = true }, function(out)
		if out.code ~= 0 then
			local msg = vim.trim((out.stderr or ''):gsub('%s+', ' '))
			vim.schedule(function()
				vim.notify('zellij action failed: ' .. msg, vim.log.levels.WARN)
			end)
		end
	end)

	return self
end

return Zellij
