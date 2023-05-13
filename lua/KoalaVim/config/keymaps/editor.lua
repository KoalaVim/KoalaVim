local map = require('KoalaVim.utils.map').map

map('n', '<F8>', function() require('KoalaVim.utils.misc').restart_nvim() end, 'Restart nvim')

-- Scroll with arrows
-- TODO: move to personal
map('', '<Down>', '<C-e>', 'Down to scroll')
map('', '<Up>', '<C-y>', 'Up to scroll')

-- Toggle spell check
map('n', '<F1>', ':set spell!<cr>', 'Toggle spell check')
map('i', '<F1>', '<C-O>:set spell!<cr>', 'Toggle spell check')

map('n', '<M-r>', '<cmd>echo "Current File Reloaded!"<cr><cmd>luafile %<cr>', 'Reload current luafile')

map('t', '<Esc>', '<C-\\><C-n>', 'Escape from terminal with escape key')

-- deploy
map('n', '<leader>b', function() require('KoalaVim.utils.misc').deploy() end, 'Build & deploy')
map('n', '<leader>B', function()
	require('KoalaVim.utils.misc').reset_deploy()
	require('KoalaVim.utils.misc').deploy()
end, 'Reset deploy, build & deploy')

map('n', ']q', '<cmd>cnext<CR>', 'Quickfix next')
map('n', '[q', '<cmd>cprev<CR>', 'Quickfix prev')
