return {
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>ff', builtin.find_files, {}) -- Поиск файлов
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})  -- Поиск текста
            vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, { desc = "Telescope LSP References" })
            vim.keymap.set('n', '<leader>fs', require('telescope.builtin').lsp_document_symbols,
                { desc = "Find Document Symbols" })
            vim.keymap.set('n', '<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols,
                { desc = "Workspace Symbols" })
        end
    },
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                    cpp = { "clang-format" },
                    c = { "clang-format" },
                    rust = { "rustfmt" },
                    python = { "isort", "black" },

                    -- Заменили prettier на biome для JS/TS стека
                    javascript = { "biome" },
                    typescript = { "biome" },
                    javascriptreact = { "biome" },
                    typescriptreact = { "biome" },
                    json = { "biome" },

                    -- Для HTML и CSS пока можно оставить prettier,
                    -- или использовать другие инструменты, если npm совсем исключен
                    css = { "prettier" },
                    html = { "prettier" },
                },
                format_on_save = {
                    lsp_fallback = true,
                    async = false,
                    timeout_ms = 500,
                },
            })
        end,
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {}
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        },
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
        },
    },
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({
                check_ts = true, -- Интеграция с treesitter
            })
        end
    }
}
