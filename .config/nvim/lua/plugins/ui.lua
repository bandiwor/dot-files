return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000,
        opts = {
            flavour = "mocha",
            term_colors = true,
            transparent_background = false,
            styles = {
                comments = { "italic" },
                keywords = { "italic" },
                functions = { "bold" },
            },
            color_overrides = {
                mocha = {
                    -- Глубокий графитовый фон (темнее, без явной синевы)
                    base = "#111317",   -- Основной фон редактора
                    mantle = "#0D0F12", -- Сайдбары (NvimTree) и плавающие окна
                    crust = "#090A0C",  -- Статусбар и самые темные элементы

                    -- Нейтральный текст (высокая читаемость, без пересвета)
                    text = "#D0D4D8",     -- Основной код
                    subtext1 = "#8A9199", -- Комментарии и неактивные элементы

                    -- Выразительные, но мягкие акценты (не блеклые)
                    red = "#E06C75",    -- Чистый красный (ошибки, теги)
                    peach = "#E59B70",  -- Приятный оранжево-персиковый (числа, константы)
                    yellow = "#D1B671", -- Теплый золотистый (типы, классы)
                    green = "#8FCA9A",  -- Свежий мятно-зеленый (строки)
                    teal = "#71C4C7",   -- Ясный бирюзовый (регулярки, escape-символы)
                    blue = "#7AADE3",   -- Небесно-голубой (функции, методы)
                    mauve = "#B690E6",  -- Красивый фиолетовый (ключевые слова, операторы)
                },
            },
            integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                notify = true,
                telescope = { enabled = true },
                indent_blankline = { enabled = true },
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master", -- Явно указываем ветку, чтобы Lazy не запутался
        config = function()
            -- pcall (protected call) перехватывает ошибку.
            -- Если плагина нет, Neovim не умрет, а пойдет загружаться дальше.
            local ok, configs = pcall(require, "nvim-treesitter.configs")

            if not ok then
                -- Выдаст аккуратное желтое уведомление вместо красного экрана смерти
                vim.notify("Treesitter скачивается или недоступен. Запусти :Lazy sync", vim.log.levels.WARN)
                return
            end

            configs.setup({
                ensure_installed = { "cpp", "bash", "markdown", "toml", "python", "rust", "wgsl", "cmake" },
                highlight = { enable = true },
                indent = { enable = true, disable = { "c", "cpp" } },
            })
        end
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
