local map = require('KoalaVim.utils.map').map

map({ 'n', 't' }, '<F8>', function()
	require('KoalaVim.utils.misc').restart_nvim()
end, 'Restart nvim')

-- Git
map('n', ']C', function()
	require('KoalaVim.utils.git').jump_to_git_dirty_file('next')
end, 'Restart nvim')

map('n', '[C', function()
	require('KoalaVim.utils.git').jump_to_git_dirty_file('prev')
end, 'Restart nvim')

-- Scroll with arrows
-- TODO: move to personal
map('', '<Down>', '<C-e>', 'Down to scroll')
map('', '<Up>', '<C-y>', 'Up to scroll')

-- Toggle spell check
map('n', '<F1>', ':set spell!<cr>', 'Toggle spell check')
map('i', '<F1>', '<C-O>:set spell!<cr>', 'Toggle spell check')

map('n', '<M-r>', '<cmd>echo "Current File Reloaded!"<cr><cmd>luafile %<cr>', 'Reload current luafile')

map('t', '<M-Esc>', '<C-\\><C-n>', 'Escape from terminal with escape key')

-- deploy
map('n', '<leader>b', function()
	require('KoalaVim.utils.build').deploy()
end, 'Build & deploy')

map('n', '<leader>B', function()
	require('KoalaVim.utils.build').reset_deploy()
	require('KoalaVim.utils.build').deploy()
end, 'Reset deploy, build & deploy')
