local map = require('KoalaVim.utils.map').map

-- Search
map('n', 'n', 'nzz', 'Auto recenter after n')
map('n', 'N', 'Nzz', 'Auto recenter after N')
map('n', '<F3>', '<cmd>let @/ = "not_gonna_find_this_______"<cr>', 'Disable find highlight')
map('i', '<F3>', '<Esc><cmd>let @/ = "not_gonna_find_this_______"<cr>i', 'Disable find highlight')

map('n', '*', "<cmd>let @/= '\\<' . expand('<cword>') . '\\>'<cr>zz", 'Search current word without jump')
