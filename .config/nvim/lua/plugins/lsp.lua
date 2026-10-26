-- Серверы: одно место, откуда берутся и ensure_installed, и vim.lsp.enable
local servers = {
    "clangd", "rust_analyzer", "lua_ls", "wgsl_analyzer",
    "basedpyright", "ruff",
    "vtsls", "html", "cssls", "eslint", "emmet_language_server", "jsonls",
    "bashls", "neocmake", "taplo", "marksman",
}

return {
    {
        "williamboman/mason.nvim",
        config = function() require("mason").setup() end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_enable = false, -- включаем явно ниже, из одного списка
            })
        end
    },
    {
        -- Форматтеры для conform (раньше нигде не ставились: black/isort/stylua/clang-format не было)
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            -- clang-format не ставим через Mason (pip-сборка падает): он идёт с пакетом clang (pacman -S clang)
            ensure_installed = { "stylua", "ruff", "biome", "prettier", "shfmt" },
            run_on_start = true,
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "p00f/clangd_extensions.nvim", "b0o/SchemaStore.nvim" },
        config = function()
            local capabilities = require('blink.cmp').get_lsp_capabilities()

            -- 1. Глобальная настройка для ВСЕХ языковых серверов
            vim.lsp.config('*', {
                capabilities = capabilities,
                root_markers = { 'package.json', 'compile_commands.json', '.git', 'Cargo.toml' },
            })

            -- 2. Точечные настройки конкретных серверов
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd", "--background-index", "--clang-tidy",
                    "--header-insertion=iwyu", "--completion-style=detailed",
                },
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

            -- Без этого lua_ls ругается "Undefined global 'vim'" в самом конфиге nvim
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = {
                            library = { vim.env.VIMRUNTIME },
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            })

            -- Python: "standard" вместо "recommended" (в basedpyright по умолчанию очень шумный),
            -- интерпретатор берётся из .venv проекта, если он есть
            vim.lsp.config("basedpyright", {
                settings = {
                    basedpyright = {
                        analysis = {
                            typeCheckingMode = "standard",
                            autoImportCompletions = true,
                            diagnosticMode = "openFilesOnly",
                            inlayHints = { callArgumentNames = true },
                        },
                    },
                },
                before_init = function(_, config)
                    local venv_python = (config.root_dir or "") .. "/.venv/bin/python"
                    if vim.uv.fs_stat(venv_python) then
                        config.settings = config.settings or {}
                        config.settings.python = vim.tbl_extend("force", config.settings.python or {},
                            { pythonPath = venv_python })
                    end
                end,
            })

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
            vim.lsp.enable(servers)

            -- 4. Хоткеи при загрузке LSP
            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'LSP actions',
                callback = function(event)
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    local opts = function(desc) return { buffer = event.buf, desc = desc } end

                    -- ruff только линтит/форматирует; hover отдаём basedpyright, чтобы не было дублей
                    if client and client.name == "ruff" then
                        client.server_capabilities.hoverProvider = false
                    end

                    if client and client.server_capabilities.inlayHintProvider then
                        vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })

                        vim.keymap.set('n', '<leader>th', function()
                            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }),
                                { bufnr = event.buf })
                        end, { buffer = event.buf, desc = "Toggle Inlay Hints" })
                    end

                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts("Go to definition"))
                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts("Go to declaration"))
                    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts("Go to implementation"))
                    vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts("Go to type definition"))
                    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts("Code action"))
                    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts("Rename symbol"))
                    vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, opts("Line diagnostics"))
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
                -- Листание меню автокомплита: Ctrl+j / Ctrl+k. Стрелки в preset 'default' тоже листают меню —
                -- отключаем: 'fallback' = обычное поведение клавиши (движение курсора)
                ['<C-j>'] = { 'select_next', 'fallback' },
                ['<C-k>'] = { 'select_prev', 'fallback' },
                ['<Up>'] = { 'fallback' },
                ['<Down>'] = { 'fallback' },
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
