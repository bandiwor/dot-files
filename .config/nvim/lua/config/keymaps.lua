vim.g.mapleader = " "


local map = vim.keymap.set

map('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Toggle File Explorer" })
map('n', '<leader>f', ':NvimTreeFocus<CR>', { desc = "Focus File Explorer" })

map('n', '<Tab>', ':BufferLineCycleNext<CR>', { desc = 'Go to next tab' })
map('n', '<S-Tab>', ':BufferLineCyclePrev<CR>', { desc = 'Go to prev tab' })
map('n', '<leader>x', ':bdelete<CR>', { desc = 'Close current tab' })

map('n', '<Up>', '<nop>')
map('n', '<Down>', '<nop>')
map('n', '<Left>', '<nop>')
map('n', '<Right>', '<nop>')

map('n', 'n', 'nzzzn')
map('n', 'N', 'Nzzzn')
