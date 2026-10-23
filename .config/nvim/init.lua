vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.opt_local.cindent = true
        -- g0: public:/private: на уровне class (как AccessModifierOffset: -4), t0: тип возврата в колонке 0,
        -- (0: переносы аргументов выравниваются по скобке. :h 'cinoptions'
        vim.opt_local.cinoptions = "g0,t0,(0"
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 4
        vim.opt_local.expandtab = true
    end,
})

require("config.options")
require("config.keymaps")
require("config.lazy")
