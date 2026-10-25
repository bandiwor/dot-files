-- Плагин языка Neon (локальный клон, не из GitHub): подсветка, LSP и хоткеи.
-- Бинарь `neon` берётся из $PATH; если лежит вне его — раскомментируй cmd.
return {
    {
        dir = "~/src/neon/editors/nvim", -- путь к клону
        name = "neon.nvim",
        ft = "neon",
        opts = {
            -- cmd = { "/home/me/.cargo/bin/neon", "lsp" },
            keymaps = true, -- gd, gr, K, <leader>rn, <leader>ds, <C-s> (в insert)
        },
    },
}
