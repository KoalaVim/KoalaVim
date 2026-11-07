local M = {}
local PLUGIN = 'koalavim-editor'

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
	local opened, err = request('plugin.pane.open', params)
	if not opened then
		vim.notify(
			'Could not open the Herdr editor: ' .. tostring(err) .. '. Opening it in Neovim instead.',
			vim.log.levels.WARN
		)
		return false
	end
	return true
end

--- Restore the agent only after Herdr removes the temporary editor pane;
--- restoring zoom before pane teardown would immediately lose it again.
function M.finish(pipe, agent, editor_pane, restore_zoom, floating)
	local util = require('sidekick.util')
	local function settle(attempt)
		-- Popups are outside pane.list/get, and process exit alone may not reap
		-- them until Herdr's next UI tick. Close ours before releasing the proxy.
		if floating == '1' then
			request('popup.close', {})
		end
		if
			floating ~= '1'
			and editor_pane ~= ''
			and util.exec({ 'herdr', 'pane', 'get', editor_pane }, { notify = false })
			and attempt < 100
		then
			vim.defer_fn(function()
				settle(attempt + 1)
			end, 50)
			return
		end
		if restore_zoom == '1' then
			util.exec({ 'herdr', 'pane', 'zoom', agent, '--on' }, { notify = false })
		else
			request('pane.focus', { pane_id = agent })
		end
		vim.system({ 'sh', '-c', 'printf "done\\n" > ' .. vim.fn.shellescape(pipe) })
	end
	vim.defer_fn(function()
		settle(1)
	end, 50)
	return 1
end

return M
