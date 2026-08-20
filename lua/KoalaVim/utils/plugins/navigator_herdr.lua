-- Herdr multiplexer backend for Navigator.nvim.
--
-- Navigator runs `wincmd <dir>` first and only calls us once the cursor is
-- already at the edge of Neovim's layout, where we hand focus to the
-- neighbouring herdr pane via the control socket.
--
-- Also manages the pane marker file that herdr-nvim-nav's C action reads to
-- determine whether Neovim owns the focused pane (so herdr can forward
-- Ctrl+h/j/k/l instead of consuming them).

---@private
---@class KoalaHerdr: Vi
---@field private pane_id string
---@field private socket_path string
---@field private payloads table<Direction, string>
local Herdr = require('Navigator.mux.vi'):new()

local uv = vim.uv or vim.loop

local DIR_MAP = { h = 'left', j = 'down', k = 'up', l = 'right' }

---Creates a new Herdr navigator instance and claims the pane marker.
---@return KoalaHerdr
function Herdr:new()
	local pane_id = vim.env.HERDR_PANE_ID
	assert(pane_id and pane_id ~= '', '[Navigator] Not running inside herdr!')

	local socket = vim.env.HERDR_SOCKET_PATH
	if not socket or socket == '' then
		socket = vim.fn.expand('~/.config/herdr/herdr.sock')
	end

	local payloads = {}
	for wincmd_dir, herdr_dir in pairs(DIR_MAP) do
		payloads[wincmd_dir] = vim.json.encode({
			id = 'nvim.nav',
			method = 'pane.focus_direction',
			params = { direction = herdr_dir, pane_id = pane_id },
		}) .. '\n'
	end

	---@type KoalaHerdr
	local state = {
		pane_id = pane_id,
		socket_path = socket,
		payloads = payloads,
	}
	self.__index = self
	local instance = setmetatable(state, self)

	instance:_setup_marker()
	return instance
end

---Write and manage the pane marker so herdr-nvim-nav's C action knows we're here.
function Herdr:_setup_marker()
	local cache = vim.env.XDG_CACHE_HOME
	if not cache or cache == '' then
		cache = vim.env.HOME .. '/.cache'
	end
	local marker_dir = cache .. '/herdr/nvim-panes'
	local path = marker_dir .. '/' .. self.pane_id

	vim.fn.mkdir(marker_dir, 'p')
	local fd = io.open(path, 'w')
	if fd then
		fd:write(tostring(uv.os_getpid()), '\n')
		fd:close()
	end

	local function claim()
		local f = io.open(path, 'w')
		if f then
			f:write(tostring(uv.os_getpid()), '\n')
			f:close()
		end
	end

	local function release()
		os.remove(path)
	end

	vim.api.nvim_create_autocmd('VimResume', { callback = claim })
	vim.api.nvim_create_autocmd({ 'VimSuspend', 'VimLeavePre' }, { callback = release })
end

---Switch pane in Herdr via the control socket.
---@param direction Direction See |navigator.api.Direction|
---@return KoalaHerdr
function Herdr:navigate(direction)
	local payload = self.payloads[direction]
	if not payload then
		return self
	end

	local pipe = uv.new_pipe(false)
	if not pipe then
		self:_navigate_cli(direction)
		return self
	end

	pipe:connect(self.socket_path, function(err)
		if err then
			pipe:close()
			vim.schedule(function()
				self:_navigate_cli(direction)
			end)
		else
			pipe:write(payload, function()
				pipe:close()
			end)
		end
	end)

	return self
end

---CLI fallback when the socket isn't reachable.
---@param direction Direction
function Herdr:_navigate_cli(direction)
	local dir = DIR_MAP[direction]
	if not dir then
		return
	end
	vim.system({ 'herdr', 'pane', 'focus', '--direction', dir, '--current' }, { text = true }, function(out)
		if out.code ~= 0 then
			local msg = vim.trim((out.stderr or ''):gsub('%s+', ' '))
			vim.schedule(function()
				vim.notify('herdr pane focus failed: ' .. msg, vim.log.levels.WARN)
			end)
		end
	end)
end

return Herdr
