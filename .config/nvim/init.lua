vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.opt_local.cindent = true
        -- Настройка того, как cindent реагирует на специфические вещи (опционально)
        -- :h 'cinoptions'
        vim.opt_local.cinoptions = "g0,t0,(0"
    end,
})

require("config.options")
require("config.keymaps")
require("config.lazy")
