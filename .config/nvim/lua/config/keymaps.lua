vim.g.mapleader = " "


local map = vim.keymap.set

map('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Toggle File Explorer" })
map('n', '<leader>f', ':NvimTreeFocus<CR>', { desc = "Focus File Explorer" })

map('n', '<Tab>', ':BufferLineCycleNext<CR>', { desc = 'Go to next tab' })
map('n', '<S-Tab>', ':BufferLineCyclePrev<CR>', { desc = 'Go to prev tab' })
map('n', '<leader>x', ':bp | bd #<CR>', { desc = 'Close current tab' })

-- Переключение между окнами: Ctrl + стрелки
map('n', '<C-Left>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-Down>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-Up>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-Right>', '<C-w>l', { desc = 'Window right' })

map('n', '<Up>', '<nop>')
map('n', '<Down>', '<nop>')
map('n', '<Left>', '<nop>')
map('n', '<Right>', '<nop>')

-- Поиск: центрируем экран и раскрываем сворачивание (было 'nzzzn' — лишний zn сбрасывал folds)
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')
