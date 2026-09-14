return {
    {
        "williamboman/mason.nvim",
        config = function() require("mason").setup() end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                -- ДОБАВЛЕНО: vtsls (JS/TS), html, cssls, eslint, emmet
                ensure_installed = {
                    "clangd", "lua_ls", "rust_analyzer",
                    "vtsls", "html", "cssls", "eslint", "emmet_language_server", "jsonls",
                    "basedpyright"
                },
            })
        end
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "p00f/clangd_extensions.nvim", "b0o/SchemaStore.nvim" },
        config = function()
            -- ИЗМЕНЕНО: Теперь мы получаем capabilities от blink.cmp
            local capabilities = require('blink.cmp').get_lsp_capabilities()

            -- 1. Глобальная настройка для ВСЕХ языковых серверов
            vim.lsp.config('*', {
                capabilities = capabilities,
                root_markers = { 'package.json', 'compile_commands.json', '.git', 'Cargo.toml' },
            })

            -- 2. Точечные настройки конкретных серверов
            vim.lsp.config("clangd", {
                cmd = { "clangd", "--background-index", "--clang-tidy" },
                init_options = {
                    usePlaceholders = true,
                    completeUnimported = true,
                    clangdFileStatus = true,
                },
            })

            vim.lsp.config("rust_analyzer", {
                settings = {
                    ["rust-analyzer"] = {
                        imports = { granularity = { group = "module" }, prefix = "self" },
                        cargo = { buildScripts = { enable = true } },
                        procMacro = { enable = true },
                        inlayHints = {
                            bindingModeHints = { enable = true },
                            typeHints = { enable = true },
                        },
                    },
                },
            })

            -- ДОБАВЛЕНО: Настройка для Emmet (чтобы он работал в нужных файлах)
            vim.lsp.config("emmet_language_server", {
                filetypes = { "css", "html", "javascript", "javascriptreact", "less", "sass", "scss", "pug", "typescriptreact" },
            })

            vim.lsp.config("vtsls", {
                settings = {
                    typescript = {
                        tsserver = {
                            pluginPaths = { "./node_modules" },
                        },
                    },
                },
            })

            vim.lsp.config("jsonls", {
                settings = {
                    json = {
                        schemas = require('schemastore').json.schemas(),
                        validate = { enable = true },
                    },
                },
            })

            -- 3. Включаем серверы
            vim.lsp.enable("clangd")
            vim.lsp.enable("lua_ls")
            vim.lsp.enable("wgsl_analyzer")
            vim.lsp.enable("rust_analyzer")

            -- ДОБАВЛЕНО: Включаем веб-серверы
            vim.lsp.enable("vtsls")
            vim.lsp.enable("html")
            vim.lsp.enable("cssls")
            vim.lsp.enable("eslint")
            vim.lsp.enable("emmet_language_server")
            vim.lsp.enable("jsonls")

            -- 4. Хоткеи при загрузке LSP
            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'LSP actions',
                callback = function(event)
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    local opts = { buffer = event.buf }

                    if client and client.server_capabilities.inlayHintProvider then
                        vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })

                        vim.keymap.set('n', '<leader>th', function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }),
                                { bufnr = event.buf })
                        end, { buffer = event.buf, desc = "Toggle Inlay Hints" })
                    end

                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
                end,
            })
        end
    },

    -- ИЗМЕНЕНО: Полностью заменили nvim-cmp на blink.cmp
    {
        'saghen/blink.cmp',
        lazy = false,                                  -- автодополнение нужно сразу
        dependencies = 'rafamadriz/friendly-snippets', -- Коллекция готовых сниппетов (включая веб)
        version = '*',
        opts = {
            -- Используем привычные хоткеи (Tab/Enter/Стрелки)
            keymap = {
                preset = 'default',
                ['<CR>'] = { 'accept', 'fallback' },
                ['<Up>'] = { 'select_prev', 'fallback' },
                ['<Down>'] = { 'select_next', 'fallback' },
            },

            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = 'mono'
            },

            -- Источники автодополнения
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },

            -- Настройка внешнего вида окна автодополнения
            completion = {
                menu = { border = 'rounded' },
                documentation = { auto_show = true, window = { border = 'rounded' } },
            },
            signature = { enabled = true, window = { border = 'rounded' } },
        }
    }
}
