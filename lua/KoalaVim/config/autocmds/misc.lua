local api = vim.api

local koala_early_autocmds = api.nvim_create_augroup('koala_early', { clear = true })

api.nvim_create_autocmd('FileType', {
	group = koala_early_autocmds,
	pattern = { 'log' },
	callback = function()
		-- Disable search wrapping for log files
		vim.opt_local.wrapscan = false
	end,
})

api.nvim_create_autocmd('BufUnload', {
	group = koala_early_autocmds,
	callback = function(args)
		if vim.bo[args.buf].filetype ~= 'sidekick_terminal' then
			return
		end
		vim.schedule(function()
			local non_floating_tabs = 0
			for _, t in ipairs(api.nvim_list_tabpages()) do
				for _, w in ipairs(api.nvim_tabpage_list_wins(t)) do
					if api.nvim_win_get_config(w).relative == '' then
						non_floating_tabs = non_floating_tabs + 1
						break
					end
				end
			end
			if non_floating_tabs > 1 then
				return
			end
			for _, b in ipairs(api.nvim_list_bufs()) do
				if b ~= args.buf and vim.bo[b].buflisted then
					local name = api.nvim_buf_get_name(b)
					local modified = vim.bo[b].modified
					if name ~= '' or modified then
						return
					end
				end
			end
			vim.cmd('qa!')
		end)
	end,
})

vim.filetype.add({
	extension = {
		mdc = 'markdown',
		tmux = 'tmux',
		tofu = 'terraform',
	},
})
