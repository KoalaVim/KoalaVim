local M = {}

local api = vim.api

local function catch(what)
	return what[1]
end

local function try(what)
	status, result = pcall(what[1])
	if not status then
		what[2](result)
	end
	return result
end

function M.close_all_but_current()
	local buf_utils = require('KoalaVim.utils.buf')
	for _, bufnr in pairs(api.nvim_list_bufs()) do
		if not buf_utils.is_visible(bufnr) and buf_utils.is_valid(bufnr) then
			try({
				function()
					Snacks.bufdelete.delete({ buf = bufnr, wipe = true })
				end,
				catch({
					function()
						-- print('Failed to delete buffer: ' .. bufnr)
					end,
				}),
			})
		end
	end
end

local function count_normal_wins()
	local count = 0
	for _, win in ipairs(api.nvim_list_wins()) do
		if api.nvim_win_get_config(win).relative == '' then
			count = count + 1
		end
	end
	return count
end

function M.close()
	local bufnr = api.nvim_get_current_buf()
	if count_normal_wins() <= 1 then
		api.nvim_feedkeys(':q\n', 'n', false)
		return
	end
	api.nvim_win_close(0, true)
	if not require('KoalaVim.utils.buf').is_visible(bufnr) then
		if api.nvim_buf_is_loaded(bufnr) then
			Snacks.bufdelete.delete({ buf = bufnr, wipe = true })
		end
	end
end

local function sidekick_split(direction)
	local in_terminal_mode = vim.fn.mode() == 't'
	if direction == 'vertical' then
		vim.cmd('vsplit')
	else
		vim.cmd('split')
	end

	local saved = {
		number = vim.wo.number,
		relativenumber = vim.wo.relativenumber,
		statuscolumn = vim.wo.statuscolumn,
		signcolumn = vim.wo.signcolumn,
		foldcolumn = vim.wo.foldcolumn,
		winbar = vim.wo.winbar,
	}

	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.statuscolumn = ''
	vim.wo.signcolumn = 'no'
	vim.wo.foldcolumn = '0'
	vim.wo.winbar = ''

	if in_terminal_mode then
		vim.cmd('stopinsert')
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, true, true), 'n', false)
	end

	local winid = api.nvim_get_current_win()
	local initial_buf = api.nvim_win_get_buf(winid)
	local group = api.nvim_create_augroup('KoalaSidekickSplit_' .. winid, { clear = true })
	api.nvim_create_autocmd('BufWinEnter', {
		group = group,
		callback = function(args)
			if not api.nvim_win_is_valid(winid) then
				api.nvim_del_augroup_by_id(group)
				return
			end
			if api.nvim_get_current_win() ~= winid or args.buf == initial_buf then
				return
			end
			api.nvim_win_call(winid, function()
				for opt, value in pairs(saved) do
					vim.wo[opt] = value
				end
			end)
			api.nvim_del_augroup_by_id(group)
		end,
	})
	api.nvim_create_autocmd('WinClosed', {
		group = group,
		pattern = tostring(winid),
		callback = function()
			api.nvim_del_augroup_by_id(group)
		end,
	})
end

function M.smart_split(direction)
	local ft = api.nvim_buf_get_option(0, 'filetype')
	if ft == 'toggleterm' then
		open_new_terminal(direction)
	elseif ft == 'sidekick_terminal' then
		sidekick_split(direction)
	else
		if direction == 'vertical' then
			vim.cmd('vsplit')
		else
			vim.cmd('split')
		end
	end
end

function M.split_if_not_exist(is_vsplit)
	-- TODO: trinary expression
	local pos_index = nil
	local split_command = nil

	if is_vsplit then
		pos_index = 1
		split_command = 'vsplit'
	else
		pos_index = 2
		split_command = 'split'
	end

	local win_ids = api.nvim_tabpage_list_wins(api.nvim_get_current_tabpage())
	local current_win = api.nvim_get_current_win()

	local current_win_pos = api.nvim_win_get_position(current_win)[pos_index]

	for _, win_id in ipairs(win_ids) do
		if win_id ~= current_win then
			local floating = api.nvim_win_get_config(win_id).relative ~= ''
			local file_type = api.nvim_buf_get_option(api.nvim_win_get_buf(win_id), 'filetype')
			if file_type ~= 'NvimTree' and not floating then
				local row = api.nvim_win_get_position(win_id)[pos_index]
				if current_win_pos == row then
					api.nvim_win_set_buf(win_id, api.nvim_win_get_buf(0))
					api.nvim_win_set_cursor(win_id, api.nvim_win_get_cursor(current_win))
					api.nvim_set_current_win(win_id)
					return
				end
			end
		end
	end

	-- Didnt return create new split
	vim.fn.execute(split_command)
end

return M
