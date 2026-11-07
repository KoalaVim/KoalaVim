-- This Neovim belongs to a temporary Herdr editor pane, so closing it applies
-- the prompt and exits this process. The host editor and its dashboard stay put.
KOALA_AUTOSAVE_SESSION = false
local prompt = vim.api.nvim_get_current_buf()
vim.bo[prompt].filetype = 'sidekick_koala_prompt'

local function save()
	if vim.api.nvim_buf_is_valid(prompt) and vim.bo[prompt].modified then
		vim.api.nvim_buf_call(prompt, function()
			vim.cmd.update()
		end)
	end
end
vim.api.nvim_create_autocmd('QuitPre', { callback = save })
local function apply()
	save()
	vim.cmd.qa()
end
for _, key in ipairs({ '<M-q>', '<M-w>' }) do
	vim.keymap.set({ 'n', 'i' }, key, apply, { buffer = prompt, desc = 'Apply prompt and close editor pane' })
end
vim.cmd('normal! G$')
vim.cmd.startinsert()
