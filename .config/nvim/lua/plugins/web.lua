return {
    {
        "windwp/nvim-ts-autotag",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-ts-autotag").setup({
                opts = {
                    enable_close = true,          -- Автоматически добавлять закрывающий тег
                    enable_rename = true,         -- Если переименовал <div> в <span>, закроется тоже <span>
                    enable_close_on_slash = true, -- Автозакрытие при вводе </ (то, что тебе нужно!)
                }
            })
        end,
    },
    {
        "brenoprata10/nvim-highlight-colors",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvim-highlight-colors").setup({
                render = 'background',  -- Закрашивает сам код цвета
                enable_tailwind = true, -- Включает поддержку TailwindCSS
            })
        end,
    }
}
