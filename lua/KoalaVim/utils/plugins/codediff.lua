local M = {}

local function repo_relative(path, git_root)
	if not path or path == '' then
		return nil
	end
	local root = git_root and git_root:gsub('/$', '') or nil
	if root and path:sub(1, #root + 1) == root .. '/' then
		return path:sub(#root + 2)
	end
	return path
end

local function get_context()
	local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
	if not ok then
		return nil
	end

	local buf = vim.api.nvim_get_current_buf()
	local tabpage = lifecycle.find_tabpage_by_buffer(buf)
	if not tabpage then
		local current_tab = vim.api.nvim_get_current_tabpage()
		local session = lifecycle.get_session(current_tab)
		local explorer = session and lifecycle.get_explorer(current_tab)
		if explorer and explorer.bufnr == buf then
			tabpage = current_tab
		end
	end
	if not tabpage then
		return nil
	end

	local session = lifecycle.get_session(tabpage)
	if not session then
		return nil
	end

	local explorer = lifecycle.get_explorer(tabpage)
	local side = nil
	local path = nil
	local revision = nil

	if buf == session.original_bufnr then
		side = 'original'
		path = session.original_path
		revision = session.original_revision
	elseif buf == session.modified_bufnr then
		side = 'modified'
		path = session.modified_path
		revision = session.modified_revision
	elseif buf == session.result_bufnr then
		side = 'result'
		path = session.modified_path
		revision = session.modified_revision
	elseif explorer and explorer.bufnr == buf then
		side = 'explorer'
		path = explorer.current_file_path
		if not path and explorer.tree then
			local node = explorer.tree:get_node()
			path = node and node.data and node.data.path or nil
		end
	end

	local rel_path = repo_relative(path, session.git_root)
	if not rel_path then
		return nil
	end

	return {
		buf = buf,
		win = vim.api.nvim_get_current_win(),
		tabpage = tabpage,
		side = side,
		path = rel_path,
		revision = revision,
		git_root = session.git_root,
		mode = session.mode,
		layout = session.layout,
	}
end

local function selection_text(ctx)
	local ok_context, context = pcall(require, 'sidekick.cli.context')
	if not ok_context then
		return nil
	end
	local range = context.selection(ctx.buf)
	if not range then
		return nil
	end

	local ok_selection, selection = pcall(require, 'sidekick.cli.context.selection')
	if not ok_selection then
		return nil
	end

	local selected = selection.get({
		buf = ctx.buf,
		range = range,
	})
	if not selected or vim.tbl_isempty(selected) then
		return nil
	end

	return selected, range
end

local function location_text(ctx, range, kind)
	local loc = require('sidekick.cli.context.location')

	local name = ctx.path
	if ctx.git_root and not name:match('^/') then
		name = ctx.git_root:gsub('/$', '') .. '/' .. name
	end

	local cursor = vim.api.nvim_win_get_cursor(ctx.win)
	return loc.get({
		name = name,
		cwd = ctx.git_root,
		row = cursor[1],
		col = cursor[2] + 1,
		range = range,
	}, { kind = kind or 'position' })
end

---@param kind 'this'|'file'|'selection'
---@return sidekick.Text[]? text
---@return boolean handled
function M.context_text(kind)
	local ctx = get_context()
	if not ctx then
		return nil, false
	end

	if kind == 'file' then
		return location_text(ctx, nil, 'file'), true
	end

	local selected, range = selection_text(ctx)
	if kind == 'selection' then
		if not selected then
			vim.notify('No CodeDiff selection to send.', vim.log.levels.WARN)
			return nil, true
		end
		local text = location_text(ctx, range, 'position')
		table.insert(text, { { '' } })
		vim.list_extend(text, selected)
		return text, true
	end

	if kind == 'this' then
		return location_text(ctx, range, 'position'), true
	end

	return nil, false
end

return M
