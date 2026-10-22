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
		original_revision = session.original_revision,
		modified_revision = session.modified_revision,
		changes = session.stored_diff_result and session.stored_diff_result.changes,
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

local SPECIAL_REVISIONS = {
	WORKING = 'working tree',
	STAGED = 'index (staged)',
	[':0'] = 'index (staged)',
	[':1'] = 'merge base (:1)',
	[':2'] = 'ours (:2)',
	[':3'] = 'theirs (:3)',
}

-- Short hash for commit refs, a readable name for special revisions.
local function revision_label(rev, git_root, cache)
	if rev == nil then
		return 'working tree'
	end
	if SPECIAL_REVISIONS[rev] then
		return SPECIAL_REVISIONS[rev]
	end
	if not cache[rev] then
		cache[rev] = rev
		if git_root then
			local out = vim.fn.systemlist({ 'git', '-C', git_root, 'rev-parse', '--short', rev })
			if vim.v.shell_error == 0 and out[1] then
				cache[rev] = out[1]
			end
		end
	end
	return cache[rev]
end

local function is_working_tree(rev)
	return rev == nil or rev == 'WORKING'
end

-- Revision of the content being referenced (the result pane is the working tree file)
local function referenced_revision(ctx)
	if ctx.side == 'original' then
		return ctx.original_revision
	elseif ctx.side == 'result' then
		return nil
	end
	return ctx.modified_revision
end

-- Whether lines [from, to] of the current side overlap a diff hunk.
-- Hunk ranges are 1-based with an exclusive end; an empty range (pure insert/delete on the
-- other side) counts as touching the lines around it.
local function touches_change(ctx, from, to)
	local key = ctx.side == 'original' and 'original' or 'modified'
	for _, change in ipairs(ctx.changes or {}) do
		local hunk = change[key]
		local hunk_start, hunk_end = hunk.start_line, hunk.end_line - 1
		if hunk_end < hunk_start then
			hunk_start, hunk_end = hunk_start - 1, hunk_start
		end
		if from <= hunk_end and to >= hunk_start then
			return true
		end
	end
	return false
end

-- e.g. ` (diff: abc123 → def456; lines from new side def456)`, or ` (lines from def456)` when the
-- referenced lines are unchanged. Working tree references are left native, they match the file on disk.
---@param text sidekick.Text[]
---@param lines? {[1]: integer, [2]: integer} referenced line range, nil for the whole file
local function append_diff_info(ctx, text, lines)
	local rev = referenced_revision(ctx)
	if not ctx.git_root or is_working_tree(rev) then
		return text
	end

	local cache = {}
	local info
	local is_pane = ctx.side == 'original' or ctx.side == 'modified'
	if is_pane and lines and not touches_change(ctx, lines[1], lines[2]) then
		info = string.format(' (lines from %s)', revision_label(rev, ctx.git_root, cache))
	else
		local original = revision_label(ctx.original_revision, ctx.git_root, cache)
		local modified = revision_label(ctx.modified_revision, ctx.git_root, cache)
		info = string.format(' (diff: %s → %s', original, modified)
		if ctx.side == 'original' then
			info = info .. string.format('; lines from old side %s', original)
		elseif ctx.side == 'modified' then
			info = info .. string.format('; lines from new side %s', modified)
		end
		info = info .. ')'
	end

	table.insert(text[1], { info, 'SidekickLocDelim' })
	return text
end

local function location_text(ctx, range, kind)
	local loc = require('sidekick.cli.context.location')

	local name = ctx.path
	if ctx.git_root and not name:match('^/') then
		name = ctx.git_root:gsub('/$', '') .. '/' .. name
	end

	local cursor = vim.api.nvim_win_get_cursor(ctx.win)
	local text = loc.get({
		name = name,
		cwd = ctx.git_root,
		row = cursor[1],
		col = cursor[2] + 1,
		range = range,
	}, { kind = kind or 'position' })

	local lines = nil
	if kind ~= 'file' then
		lines = range and { math.min(range.from[1], range.to[1]), math.max(range.from[1], range.to[1]) }
			or { cursor[1], cursor[1] }
	end
	return append_diff_info(ctx, text, lines)
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
