return {
    {
        "williamboman/mason.nvim",
        config = function() require("mason").setup() end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "clangd", "lua_ls", "rust_analyzer" },
            })
        end
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "p00f/clangd_extensions.nvim" },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- 1. Глобальная настройка для ВСЕХ языковых серверов
            vim.lsp.config('*', {
                capabilities = capabilities,
                -- Жизненно важно для C/C++ и Rust: указываем маркеры корня проекта
                root_markers = { 'compile_commands.json', '.git', 'Cargo.toml' },
            })

            -- 2. Точечные настройки конкретных серверов (вместо старого setup)
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

            -- 3. Включаем серверы новым нативным методом Neovim
            vim.lsp.enable("clangd")
            vim.lsp.enable("lua_ls")
            vim.lsp.enable("wgsl_analyzer")
            vim.lsp.enable("rust_analyzer")

            -- 4. Назначаем хоткеи ТОЛЬКО когда LSP загрузился в конкретном файле
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

                    -- Примечание: в Neovim 0.11+ K (Hover), grn (Rename), gra (Code Action)
                    -- уже работают из коробки! Переопределяем только кастомные:
                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
                end,
            })
        end
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp", -- Источник от LSP
            "hrsh7th/cmp-buffer",   -- Источник из текста файла
            "hrsh7th/cmp-path",     -- Пути к файлам
            "L3MON4D3/LuaSnip",     -- Сниппеты
            "saadparwaiz1/cmp_luasnip",
            "onsails/lspkind.nvim"
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")

            cmp.setup({
                formatting = {
                    format = lspkind.cmp_format({
                        mode = "symbol_text", -- Показывает иконку и текст
                        maxwidth = 50,
                        ellipsis_char = "...",
                        menu = { -- Подсказки, откуда пришло
                            nvim_lsp = "[LSP]",
                            luasnip = "[Snip]",
                            buffer = "[Buf]",
                            path = "[Path]",
                        },
                    }),
                },
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp', priority = 1000 },
                    { name = 'luasnip',  priority = 750 },
                    { name = 'path',     priority = 500 },
                }, {
                    { name = 'buffer', priority = 250 },
                }),
                sorting = {
                    priority_weight = 2,
                    comparators = {
                        cmp.config.compare.offset, -- Сначала то, что ближе к курсору
                        cmp.config.compare.exact,  -- Точное совпадение
                        cmp.config.compare.score,  -- Очки от LSP

                        -- Поднимаем поля и методы выше сниппетов и текста
                        function(entry1, entry2)
                            local kind1 = entry1:get_kind()
                            local kind2 = entry2:get_kind()
                            kind1 = kind1 == cmp.lsp.CompletionItemKind.Text and 100 or kind1
                            kind2 = kind2 == cmp.lsp.CompletionItemKind.Text and 100 or kind2
                            if kind1 ~= kind2 then
                                if kind1 == cmp.lsp.CompletionItemKind.Snippet then return false end
                                if kind2 == cmp.lsp.CompletionItemKind.Snippet then return true end
                                local diff = kind1 - kind2
                                if diff < 0 then
                                    return true
                                elseif diff > 0 then
                                    return false
                                end
                            end
                        end,

                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
            })
        end
    }
}
