return {
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            compile = false,
            undercurl = true,
            commentStyle = { italic = true },
            functionStyle = { bold = false },
            keywordStyle = { italic = false },
            statementStyle = { bold = false },
            typeStyle = {},
            transparent = false,
            dimInactive = false,
            terminalColors = true,
            theme = "dragon",
            background = {
                dark = "dragon",
                light = "lotus",
            },
            colors = {
                theme = {
                    dragon = {
                        ui = {
                            bg = "#0a0a0a",
                            bg_gutter = "#0a0a0a",
                        },
                    },
                },
            },
            overrides = function(colors)
                return {
                    -- Бесшовный фон и поля
                    Normal = { bg = "#0a0a0a" },
                    NormalNC = { bg = "#0a0a0a" },
                    SignColumn = { bg = "#0a0a0a" },
                    EndOfBuffer = { fg = "#0a0a0a" },
                    LineNr = { fg = "#3a4048", bg = "#0a0a0a" },
                    CursorLine = { bg = "#141416" },
                    CursorLineNr = { fg = "#ffffff", bold = true, bg = "#0a0a0a" },

                    -- ─── ИСПРАВЛЕНИЕ СИНЕВЫ В BLINK.CMP ───
                    BlinkCmpMenu = { bg = "#0a0a0a", fg = "#d4d8dc" },
                    BlinkCmpMenuBorder = { fg = "#333333", bg = "#0a0a0a" },
                    BlinkCmpMenuSelection = { bg = "#1e2127", fg = "#ffffff", bold = true },
                    BlinkCmpLabel = { fg = "#d4d8dc" },
                    BlinkCmpLabelMatch = { fg = "#ffffff", bold = true },
                    -- Убираем синий фон у параметров функций и описаний типов:
                    BlinkCmpLabelDetail = { fg = "#6c747d", bg = "NONE" },
                    BlinkCmpLabelDescription = { fg = "#6c747d", bg = "NONE" },
                    BlinkCmpKind = { fg = "#8a9199", bg = "NONE" },
                    BlinkCmpSource = { fg = "#444444", bg = "NONE" },
                    BlinkCmpGhostText = { fg = "#444444", bg = "NONE" },
                    BlinkCmpDoc = { bg = "#0a0a0a", fg = "#d4d8dc" },
                    BlinkCmpDocBorder = { fg = "#333333", bg = "#0a0a0a" },
                    BlinkCmpSignatureHelp = { bg = "#0a0a0a", fg = "#d4d8dc" },
                    BlinkCmpSignatureHelpBorder = { fg = "#333333", bg = "#0a0a0a" },
                    BlinkCmpSignatureHelpActiveParameter = { fg = "#ffffff", bold = true, underline = true, bg = "NONE" },

                    -- ─── МЯГКАЯ ДИАГНОСТИКА (ПЕПЕЛЬНО-КИРПИЧНЫЙ ВМЕСТО ЯДОВИТО-КРАСНОГО) ───
                    DiagnosticError = { fg = "#a65454" },
                    DiagnosticSignError = { fg = "#a65454", bg = "#0a0a0a" },
                    -- Текст ошибки в конце строки становится приглушенным и не бьет по глазам:
                    DiagnosticVirtualTextError = { fg = "#6b3b3b", bg = "NONE", italic = true },
                    DiagnosticUnderlineError = { sp = "#a65454", underline = true },
                    DiagnosticFloatingError = { fg = "#a65454" },

                    -- Предупреждения (сухой песочный оттенок)
                    DiagnosticWarn = { fg = "#8a7a50" },
                    DiagnosticSignWarn = { fg = "#8a7a50", bg = "#0a0a0a" },
                    DiagnosticVirtualTextWarn = { fg = "#5a5036", bg = "NONE" },
                    DiagnosticUnderlineWarn = { sp = "#8a7a50", underline = true },

                    -- Инфо и хинты (приглушенный сланец)
                    DiagnosticInfo = { fg = "#5c6a72" },
                    DiagnosticSignInfo = { fg = "#5c6a72", bg = "#0a0a0a" },
                    DiagnosticVirtualTextInfo = { fg = "#3e474d", bg = "NONE" },
                    DiagnosticHint = { fg = "#5c6a72" },
                    DiagnosticSignHint = { fg = "#5c6a72", bg = "#0a0a0a" },
                    DiagnosticVirtualTextHint = { fg = "#3e474d", bg = "NONE" },

                    TreesitterContext = { bg = "#0e0e10" },
                    TreesitterContextLineNumber = { fg = "#3a4048", bg = "#0e0e10" },
                    TreesitterContextBottom = { sp = "#333333", underline = true },

                    FloatBorder = { fg = "#333333", bg = "#0a0a0a" },
                    NormalFloat = { bg = "#0a0a0a" },
                }
            end,
        },
        config = function(_, opts)
            require("kanagawa").setup(opts)
            vim.cmd.colorscheme("kanagawa-dragon")
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install({
                "c", "cpp", "lua", "bash", "markdown", "markdown_inline",
                "toml", "python", "rust", "wgsl", "cmake", "html", "css",
                "javascript", "typescript", "tsx", "json", "jsonc", "yaml",
                "vim", "vimdoc", "regex", "diff", "gitcommit"
            })

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
                callback = function(event)
                    pcall(vim.treesitter.start, event.buf)
                    -- Для C/C++ отступы считает cindent (см. init.lua + cinoptions), он согласован с clang-format
                    local ft = vim.bo[event.buf].filetype
                    if ft ~= "c" and ft ~= "cpp" then
                        vim.bo[event.buf].indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
                    end
                end,
            })
        end,
    },
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("nvim-tree").setup({
                view = {
                    width = 25,
                    side = "left",
                },
                renderer = {
                    group_empty = true,
                },
                filters = {
                    dotfiles = false,
                },
            })
        end,
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require("lualine").setup({
                options = {
                    globalstatus = true,
                    icons_enabled = true,
                    theme = 'auto',
                    component_separators = { left = '', right = '' },
                    section_separators = { left = '', right = '' },
                    disabled_filetypes = { 'NvimTree', 'packer' },
                },
                sections = {
                    lualine_a = { 'mode' },
                    lualine_b = { 'branch', 'diff', 'diagnostics' },
                    lualine_c = { 'filename' },
                    lualine_x = { 'encoding', 'fileformat', 'filetype' },
                    lualine_y = { 'progress' },
                    lualine_z = { 'location' }
                },
            })
        end
    },
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            vim.opt.showtabline = 2
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    separator_style = "slant",
                    diagnostics = "nvim_lsp",
                    offsets = {
                        {
                            filetype = "NvimTree",
                            text = function()
                                return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                            end,
                            text_align = "center",
                        }
                    },
                }
            })
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                current_line_blame = true, -- Показывать автора строки серым текстом справа
                current_line_blame_opts = { delay = 500 },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Навигация по изменениям (hunks)
                    map('n', ']c', function()
                        if vim.wo.diff then return ']c' end
                        vim.schedule(function() gs.next_hunk() end)
                        return '<Ignore>'
                    end, { expr = true })

                    map('n', '[c', function()
                        if vim.wo.diff then return '[c' end
                        vim.schedule(function() gs.prev_hunk() end)
                        return '<Ignore>'
                    end, { expr = true })

                    -- Показать изменения в плавающем окне
                    map('n', '<leader>hp', gs.preview_hunk)
                end
            })
        end
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify", -- Красивые уведомления справа сверху
        },
        opts = {
            lsp = {
                -- Прогресс LSP ("✓ basedpyright" на каждый переанализ) только спамит уведомлениями
                progress = { enabled = false },
                -- Подменяет стандартные обработчики lsp (hover, signature help) на красивые окна
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = true,         -- Поиск / внизу (классика), или false для центра
                command_palette = true,       -- Cmdline по центру экрана
                long_message_to_split = true, -- Длинные сообщения в сплит
            },
        }
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            max_lines = 3,           -- Максимальное количество строк контекста
            multiline_threshold = 1, -- Ограничение для многострочных сигнатур
            trim_scope = "outer",    -- Обрезать внешний контекст, если места не хватает
            mode = "cursor",         -- Вычислять контекст по положению курсора
        },
    },
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        opts = {}, -- Оставляем пустым, lazy сам вызовет require("nvim-surround").setup()
    },
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = true,
            sign_priority = 8,
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG" } },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
            },
        },
        keys = {
            -- Поиск TODO через твой Telescope
            { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
        },
    },
}
