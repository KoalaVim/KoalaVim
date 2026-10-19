local M = {}

local function in_visual_mode()
	local mode = vim.fn.mode()
	return mode == 'v' or mode == 'V' or mode == '\22'
end

-- Nodes on every row of the current visual selection (deduped), leaving visual mode
local function visual_nodes(api)
	local from, to = vim.fn.line('v'), vim.fn.line('.')
	if from > to then
		from, to = to, from
	end

	local win = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(win)
	local nodes, seen = {}, {}
	for row = from, to do
		vim.api.nvim_win_set_cursor(win, { row, 0 })
		local node = api.tree.get_node_under_cursor()
		if node and not seen[node] then
			seen[node] = true
			table.insert(nodes, node)
		end
	end

	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
	pcall(vim.api.nvim_win_set_cursor, win, cursor)
	return nodes
end

---@param kind 'this'|'file'|'selection'
---@return sidekick.Text[]? text
---@return boolean handled
function M.context_text(kind)
	if vim.bo.filetype ~= 'NvimTree' then
		return nil, false
	end
	if kind ~= 'this' and kind ~= 'file' and kind ~= 'selection' then
		return nil, false
	end

	local api = require('nvim-tree.api')

	local nodes
	local from_marks = false
	if in_visual_mode() then
		nodes = visual_nodes(api)
	else
		local marks = api.marks.list()
		if marks and #marks > 0 then
			nodes = vim.list_extend({}, marks)
			table.sort(nodes, function(a, b)
				return (a.absolute_path or '') < (b.absolute_path or '')
			end)
			from_marks = true
		else
			nodes = { api.tree.get_node_under_cursor() }
		end
	end

	-- The root header line (`..`) has no parent and isn't a referenceable node
	nodes = vim.tbl_filter(function(node)
		return node and node.absolute_path and node.parent
	end, nodes)
	if #nodes == 0 then
		vim.notify('No nvim-tree node to reference', vim.log.levels.WARN)
		return nil, true
	end

	local loc = require('sidekick.cli.context.location')
	local line = {}
	for _, node in ipairs(nodes) do
		local ref = loc.get({ name = node.absolute_path }, { kind = 'file' })[1]
		if ref then
			if #line > 0 then
				table.insert(line, { ' ' })
			end
			vim.list_extend(line, ref)
			if node.type == 'directory' then
				table.insert(line, { '/', 'SidekickLocFile' })
			end
		end
	end

	if from_marks then
		api.marks.clear()
	end

	if #line == 0 then
		vim.notify('No nvim-tree node to reference', vim.log.levels.WARN)
		return nil, true
	end
	return { line }, true
end

return M
