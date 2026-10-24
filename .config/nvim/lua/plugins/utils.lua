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
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>cf",
                function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
                mode = { "n", "v" },
                desc = "Format buffer",
            },
        },
        config = function()
            local conform = require("conform")

            -- Есть ли конфиг формататора выше по дереву каталогов (проект > ~ > встроенные настройки)
            local function has_config(ctx, names)
                return vim.fs.find(names, { upward = true, path = ctx.dirname })[1] ~= nil
            end

            -- Встроенный стиль на случай, если нет ни проектного, ни ~/.clang-format.
            -- Без него clang-format молча падает в LLVM-стиль с отступом 2 пробела.
            local clang_fallback = "{BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never,"
                .. " ColumnLimit: 100, AccessModifierOffset: -4, IndentCaseLabels: true}"

            conform.setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                    c = { "clang-format" },
                    cpp = { "clang-format" },
                    rust = { "rustfmt", lsp_format = "fallback" },

                    -- ruff: сортировка импортов + форматирование (замена isort + black, на порядок быстрее)
                    python = { "ruff_organize_imports", "ruff_format", lsp_format = "fallback" },

                    -- Biome работает, когда в проекте есть biome.json; иначе — форматирование от LSP
                    javascript = { "biome", lsp_format = "fallback" },
                    typescript = { "biome", lsp_format = "fallback" },
                    javascriptreact = { "biome", lsp_format = "fallback" },
                    typescriptreact = { "biome", lsp_format = "fallback" },
                    json = { "biome", lsp_format = "fallback" },
                    jsonc = { "biome", lsp_format = "fallback" },

                    css = { "prettier" },
                    html = { "prettier" },
                    sh = { "shfmt" },
                },
                formatters = {
                    ["clang-format"] = {
                        args = function(_, ctx)
                            local args = { "-assume-filename", ctx.filename }
                            if not has_config(ctx, { ".clang-format", "_clang-format" }) then
                                table.insert(args, "--style=" .. clang_fallback)
                            end
                            return args
                        end,
                    },
                    stylua = {
                        prepend_args = function(_, ctx)
                            if has_config(ctx, { "stylua.toml", ".stylua.toml" }) then return {} end
                            return { "--indent-type", "Spaces", "--indent-width", "4" }
                        end,
                    },
                    prettier = {
                        prepend_args = function(_, ctx)
                            if has_config(ctx, { ".prettierrc", ".prettierrc.json", ".prettierrc.yaml",
                                    "prettier.config.js", "prettier.config.mjs" }) then
                                return {}
                            end
                            return { "--tab-width", "4" }
                        end,
                    },
                    shfmt = { prepend_args = { "-i", "4" } },
                },
                format_on_save = function(bufnr)
                    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                        return
                    end
                    return { timeout_ms = 1000, lsp_format = "fallback" }
                end,
            })

            -- :FormatDisable[!] / :FormatEnable[!] — отключить автоформат (! — только для буфера)
            vim.api.nvim_create_user_command("FormatDisable", function(args)
                if args.bang then vim.b.disable_autoformat = true else vim.g.disable_autoformat = true end
            end, { bang = true, desc = "Disable autoformat on save" })
            vim.api.nvim_create_user_command("FormatEnable", function()
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
            end, { desc = "Re-enable autoformat on save" })
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
