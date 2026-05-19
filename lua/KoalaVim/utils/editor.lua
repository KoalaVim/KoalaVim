local M = {}

local function parse_file_and_line()
	local cfile = vim.fn.expand('<cfile>')
	if not cfile or cfile == '' then
		return nil, nil
	end

	local line_text = vim.fn.getline('.')
	local _, _, l = line_text:find(vim.pesc(cfile) .. ':L(%d+)')
	if not l then
		_, _, l = line_text:find(vim.pesc(cfile) .. ':(%d+)')
	end

	return cfile, l and tonumber(l) or nil
end

function M.goto_file_with_line()
	local cfile, lnum = parse_file_and_line()
	if not cfile then
		return
	end

	if lnum then
		vim.cmd('normal! gf')
		vim.api.nvim_win_set_cursor(0, { lnum, 0 })
	else
		vim.cmd('normal! gF')
	end
end

local SKIP_FT = { sidekick_terminal = true, alpha = true, NvimTree = true, toggleterm = true }

local function find_editor_win(tabpage)
	tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
		if vim.api.nvim_win_get_config(win).relative == '' then
			local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
			if not SKIP_FT[ft] then
				return win
			end
		end
	end
end

local RESET_WIN_OPTS = {
	'winhighlight',
	'signcolumn',
	'number',
	'relativenumber',
	'statuscolumn',
	'winbar',
	'foldcolumn',
}

function M.sidekick_goto_file(with_line)
	local cfile, lnum = parse_file_and_line()
	if not cfile then
		return
	end
	if not with_line then
		lnum = nil
	end

	-- Resolve to absolute path before switching windows
	local fpath = vim.fn.findfile(cfile)
	if fpath ~= '' then
		fpath = vim.fn.fnamemodify(fpath, ':p')
	elseif vim.fn.filereadable(cfile) == 1 then
		fpath = vim.fn.fnamemodify(cfile, ':p')
	else
		vim.notify('File not found: ' .. cfile, vim.log.levels.ERROR)
		return
	end

	-- Stay in normal mode when returning to this terminal buffer
	local sidekick_buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_create_autocmd('BufEnter', {
		buffer = sidekick_buf,
		once = true,
		callback = function()
			vim.schedule(function()
				vim.cmd('stopinsert')
			end)
		end,
	})

	local target_win = find_editor_win()
	local created_split = false

	if not target_win then
		-- No editor window in current tabpage, try previous tabpage (zoomed sidekick)
		local tabs = vim.api.nvim_list_tabpages()
		local cur_tab = vim.api.nvim_get_current_tabpage()
		for i, t in ipairs(tabs) do
			if t == cur_tab and i > 1 then
				target_win = find_editor_win(tabs[i - 1])
				break
			end
		end
	end

	if not target_win then
		vim.cmd('aboveleft vsplit')
		target_win = vim.api.nvim_get_current_win()
		created_split = true
	end

	vim.api.nvim_set_current_win(target_win)
	vim.cmd('edit ' .. vim.fn.fnameescape(fpath))

	if created_split then
		for _, opt in ipairs(RESET_WIN_OPTS) do
			vim.wo[target_win][opt] = vim.api.nvim_get_option_value(opt, { scope = 'global' })
		end
		vim.wo[target_win].winhighlight = ''
	end

	if lnum then
		vim.api.nvim_win_set_cursor(0, { lnum, 0 })
	end

	vim.cmd('stopinsert')
end

return M
