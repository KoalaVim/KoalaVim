local map = require('KoalaVim.utils.map').map

-- stylua: ignore start
-- Splits
map('n', '<leader>qa', function() require('KoalaVim.utils.splits').close_all_but_current() end,
	'Close all buffers but current')
map('n', '<leader>qA', '<cmd>wqa!<cr>', 'Write all + close vim')

map('n', '<M-e>', function() require('KoalaVim.utils.splits').smart_split('vertical') end, 'Vsplit')
map('n', '<M-o>', function() require('KoalaVim.utils.splits').smart_split('horizontal') end, 'split')

map('n', '<M-q>', function() require('KoalaVim.utils.splits').close() end, 'Close split')
map('n', '<M-w>', function() require('KoalaVim.utils.splits').close() end, 'Close split')
map('t', '<M-q>', '<cmd>bd!<CR>', 'Close terminal')

-- Duplicate your view into split (MAX 2)
map('n', 'gV', function() require('KoalaVim.utils.splits').split_if_not_exist(true) end, 'Vertical split if not exist')
map('n', 'gX', function() require('KoalaVim.utils.splits').split_if_not_exist(false) end, 'Horziontal split if not exist')
-- stylua: ignore end
