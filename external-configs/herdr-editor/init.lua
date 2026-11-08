-- This Neovim belongs to a temporary Herdr editor pane, so closing it applies
-- the prompt and exits this process. The host editor and its dashboard stay put.
KOALA_AUTOSAVE_SESSION = false
local prompt = vim.api.nvim_get_current_buf()
vim.bo[prompt].filetype = 'sidekick_koala_prompt'

local function save()
	if vim.api.nvim_buf_is_valid(prompt) and vim.bo[prompt].modified then
		vim.api.nvim_buf_call(prompt, function()
			vim.cmd('silent update')
		end)
	end
end
local notified = false
local function finish()
	if notified then
		return
	end
	local channel = vim.fn.sockconnect('pipe', vim.env.KOALA_EDITOR_HOST, { rpc = true })
	if channel <= 0 then
		return
	end
	local ok =
		pcall(vim.rpcrequest, channel, 'nvim_exec_lua', "return require('KoalaVim.utils.ai.mux_editor').finish(...)", {
			vim.env.KOALA_EDITOR_PIPE,
			vim.env.KOALA_EDITOR_AGENT,
			vim.env.HERDR_PANE_ID or '',
			vim.env.KOALA_EDITOR_RESTORE_ZOOM,
			vim.env.KOALA_EDITOR_FLOATING,
		})
	pcall(vim.fn.chanclose, channel)
	notified = ok
end
vim.api.nvim_create_autocmd('QuitPre', {
	callback = function()
		save()
		-- The usual single-window editor can apply before slow VimLeave hooks.
		-- Preserve quit's modified-buffer checks if other edits exist.
		if #vim.api.nvim_list_wins() == 1 then
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.bo[buf].buflisted and vim.bo[buf].modified then
					return
				end
			end
			finish()
		end
	end,
})
vim.api.nvim_create_autocmd('VimLeavePre', { once = true, callback = finish })
local function apply()
	save()
	vim.cmd.qa()
end
for _, key in ipairs({ '<M-q>', '<M-w>' }) do
	vim.keymap.set({ 'n', 'i' }, key, apply, { buffer = prompt, desc = 'Apply prompt and close editor pane' })
end
vim.cmd('normal! G$')
vim.cmd.startinsert({ bang = true })
