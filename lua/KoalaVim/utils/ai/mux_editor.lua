local M = {}
local PLUGIN = 'koalavim-editor'
local layouts = {}
local pending = {}

-- Popup placement is available over the socket even in Herdr versions whose
-- CLI does not expose it. Keep the request bounded if the server is unavailable.
local function request(method, params)
	local socket = vim.env.HERDR_SOCKET_PATH
	if not socket or socket == '' then
		return nil, 'HERDR_SOCKET_PATH is not set'
	end
	local client = assert(vim.uv.new_pipe(false))
	local done, response, failure = false, nil, nil
	local function finish(data, err)
		if done then
			return
		end
		done, response, failure = true, data, err
		client:read_stop()
		if not client:is_closing() then
			client:close()
		end
	end
	client:connect(socket, function(err)
		if err then
			return finish(nil, err)
		end
		local buffer = ''
		client:read_start(function(read_err, data)
			if read_err or not data then
				return finish(nil, read_err or 'Herdr closed the connection')
			end
			buffer = buffer .. data
			local line = buffer:match('^([^\n]*)\n')
			if not line then
				return
			end
			local ok, decoded = pcall(vim.json.decode, line)
			if not ok or type(decoded) ~= 'table' then
				return finish(nil, 'Invalid Herdr response')
			end
			if decoded.error then
				return finish(nil, decoded.error.message or vim.inspect(decoded.error))
			end
			finish(decoded.result)
		end)
		client:write(vim.json.encode({ id = 'koala.editor', method = method, params = params }) .. '\n')
	end)
	vim.wait(2000, function()
		return done
	end, 5)
	if not done then
		finish(nil, 'Herdr editor request timed out')
	end
	return response, failure
end

local function contains(outer, inner)
	return inner.x >= outer.x
		and inner.y >= outer.y
		and inner.x + inner.width <= outer.x + outer.width
		and inner.y + inner.height <= outer.y + outer.height
end

local function split_key(split)
	-- The traversal index changes while an editor split exists; the tree path
	-- of the original Neovim pane's parent stays stable.
	return split.id:match('^split_%d+_(.+)$')
end

local function host_split(layout)
	if not layout then
		return
	end
	local host
	for _, pane in ipairs(layout.panes) do
		if pane.pane_id == vim.env.HERDR_PANE_ID then
			host = pane
		end
	end
	if not host then
		return
	end
	local parent
	for _, split in ipairs(layout.splits) do
		if
			contains(split.rect, host.rect)
			and (not parent or split.rect.width * split.rect.height < parent.rect.width * parent.rect.height)
		then
			parent = split
		end
	end
	if not parent then
		return
	end
	local axis, size = parent.direction == 'right' and 'x' or 'y', parent.direction == 'right' and 'width' or 'height'
	local first = host.rect[axis] + host.rect[size] / 2 < parent.rect[axis] + parent.rect[size] * parent.ratio
	return {
		pane = host.pane_id,
		key = split_key(parent),
		direction = parent.direction,
		ratio = parent.ratio,
		small = first and 0.1 or 0.9,
	}
end

local function resize_to(saved, ratio)
	for _ = 1, 3 do
		local result = request('pane.layout', { pane_id = saved.pane })
		local layout = result and result.layout
		if not layout then
			return false
		end
		local split
		for _, candidate in ipairs(layout.splits) do
			if split_key(candidate) == saved.key and candidate.direction == saved.direction then
				split = candidate
			end
		end
		if not split then
			return false
		end
		local delta = ratio - split.ratio
		if math.abs(delta) < 0.00001 then
			return true
		end
		local axis, size = split.direction == 'right' and 'x' or 'y', split.direction == 'right' and 'width' or 'height'
		local boundary = split.rect[axis] + split.rect[size] * split.ratio
		local target, distance
		for _, pane in ipairs(layout.panes) do
			local rect = pane.rect
			local first = rect[axis] + rect[size] / 2 < boundary
			if contains(split.rect, rect) and first == (delta > 0) then
				local edge = delta > 0 and rect[axis] + rect[size] or rect[axis]
				local gap = math.abs(edge - boundary)
				if not distance or gap < distance then
					target, distance = pane.pane_id, gap
				end
			end
		end
		if not target then
			return false
		end
		local direction = split.direction == 'right' and (delta > 0 and 'right' or 'left')
			or (delta > 0 and 'down' or 'up')
		if
			not request(
				'pane.resize',
				{ pane_id = target, direction = direction, amount = math.min(math.abs(delta), 0.5) }
			)
		then
			return false
		end
	end
	return false
end

---@param file string
---@param pipe string
---@param caller_pane string
---@param layout string
---@return boolean opened
function M.open(file, pipe, caller_pane, layout)
	local direction = ({ ['pane-right'] = 'right', ['pane-down'] = 'down' })[layout]
	if layout ~= 'floating' and not direction then
		vim.notify('Invalid ai.mux.editor: ' .. tostring(layout), vim.log.levels.WARN)
		return false
	end
	local util = require('sidekick.util')
	local manifest = vim.api.nvim_get_runtime_file('external-configs/herdr-editor/herdr-plugin.toml', false)[1]
	if not manifest then
		vim.notify('Herdr editor plugin is missing; opening the editor in Neovim', vim.log.levels.WARN)
		return false
	end
	local root = vim.fs.dirname(manifest)
	if not M._linked then
		if not util.exec({ 'herdr', 'plugin', 'link', root, '--enabled' }, { notify = true }) then
			return false
		end
		M._linked = true
	end

	local _, raw = util.exec({ 'herdr', 'pane', 'layout', '--pane', caller_pane }, { notify = false })
	local ok, data = pcall(vim.json.decode, raw or '')
	local result = ok and type(data) == 'table' and data.result
	local previous = type(result) == 'table' and result.layout
	local restore_zoom = type(previous) == 'table' and previous.zoomed == true
	local saved_layout = host_split(type(previous) == 'table' and previous or nil)

	-- The child uses the same Neovim and config as its host, with an independent
	-- server and no AI launch mode or session saving.
	local config = vim.fn.stdpath('config') .. '/init.lua'
	if vim.fn.filereadable(config) == 0 then
		config = 'NONE'
	end
	local env = {
		KOALA_EDITOR_NVIM = vim.v.progpath,
		KOALA_EDITOR_HOST = vim.v.servername,
		KOALA_EDITOR_CONFIG = config,
		KOALA_EDITOR_INIT = root .. '/init.lua',
		KOALA_EDITOR_SCRIPT = root .. '/editor.sh',
		KOALA_EDITOR_FILE = file,
		KOALA_EDITOR_PIPE = pipe,
		KOALA_EDITOR_AGENT = caller_pane,
		KOALA_EDITOR_RESTORE_ZOOM = restore_zoom and '1' or '0',
		KOALA_EDITOR_FLOATING = layout == 'floating' and '1' or '0',
		KOALA_EDITOR_HERDR = vim.fn.exepath('herdr'),
		PATH = vim.env.PATH or '',
	}
	for _, key in ipairs({
		'NVIM_APPNAME',
		'KOALA_KVIM_CONF',
		'XDG_CONFIG_HOME',
		'XDG_DATA_HOME',
		'XDG_STATE_HOME',
		'XDG_CACHE_HOME',
	}) do
		if vim.env[key] then
			env[key] = vim.env[key]
		end
	end
	local params = {
		plugin_id = PLUGIN,
		entrypoint = 'editor',
		placement = layout == 'floating' and 'popup' or 'split',
		cwd = vim.fn.getcwd(),
		focus = true,
		env = env,
	}
	if direction then
		params.target_pane_id = caller_pane
		params.direction = direction
		if restore_zoom then
			util.exec({ 'herdr', 'pane', 'zoom', caller_pane, '--off' }, { notify = false })
		end
	else
		params.width, params.height = '80%', '80%'
		-- Popups target Herdr's active pane, unlike ordinary splits.
		local focused, focus_err = request('pane.focus', { pane_id = caller_pane })
		if not focused then
			vim.notify('Could not focus the Herdr editor target: ' .. tostring(focus_err), vim.log.levels.WARN)
			return false
		end
	end
	if saved_layout then
		layouts[pipe] = saved_layout
		resize_to(saved_layout, saved_layout.small)
	end
	pending[pipe] = true
	local opened, err = request('plugin.pane.open', params)
	if not opened then
		if saved_layout then
			resize_to(saved_layout, saved_layout.ratio)
		end
		layouts[pipe] = nil
		pending[pipe] = nil
		vim.notify(
			'Could not open the Herdr editor: ' .. tostring(err) .. '. Opening it in Neovim instead.',
			vim.log.levels.WARN
		)
		return false
	end
	return true
end

--- Release the agent immediately, then remove the temporary editor pane and
--- restore its layout. Completion can arrive from both Neovim and its wrapper.
function M.finish(pipe, agent, editor_pane, restore_zoom, floating)
	if not pending[pipe] then
		return 1
	end
	pending[pipe] = nil
	local saved_layout = layouts[pipe]
	layouts[pipe] = nil
	local quoted_pipe = vim.fn.shellescape(pipe)
	vim.system({ 'sh', '-c', 'if [ -p ' .. quoted_pipe .. ' ]; then printf "done\\n" > ' .. quoted_pipe .. '; fi' })
	vim.schedule(function()
		if floating == '1' then
			request('popup.close', {})
		elseif editor_pane ~= '' and editor_pane ~= agent and editor_pane ~= vim.env.HERDR_PANE_ID then
			request('pane.close', { pane_id = editor_pane })
		end
		if saved_layout then
			resize_to(saved_layout, saved_layout.ratio)
		end
		if restore_zoom == '1' then
			request('pane.zoom', { pane_id = agent, mode = 'on' })
		else
			request('pane.focus', { pane_id = agent })
		end
	end)
	return 1
end

return M
