local M = {}

function M.setup()
    require("catppuccin").setup({
        flavour = "mocha",
        color_overrides = {
            mocha = {
                -- Фоны берем динамически из системы (Noctalia)
                base = '{{colors.surface.default.hex}}',
                mantle = '{{colors.surface_container.default.hex}}',
                crust = '{{colors.surface_container_high.default.hex}}',

                -- Основной текст тоже из системы, чтобы не сливался с фоном
                text = '{{colors.on_surface.default.hex}}',

                -- А синтаксис останется сочными цветами Catppuccin!
            }
        },
        integrations = {
            cmp = true,
            gitsigns = true,
            nvimtree = true,
            treesitter = true, -- Treesitter снова будет работать идеально!
        }
    })
    vim.cmd.colorscheme("catppuccin")
end

-- Слушаем сигнал от Noctalia для обновления на лету
local signal = vim.uv.new_signal()
signal:start('sigusr1', vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
end))

return M
