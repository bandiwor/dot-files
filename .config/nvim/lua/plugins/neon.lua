-- Плагин языка Neon (https://github.com/bandiwor/neon, подкаталог editors/nvim):
-- подсветка, отступы, LSP (`neon lsp`) и команды :NeonRun/:NeonCheck/...
-- Бинарь `neon` должен быть в $PATH (cargo install --path . в репозитории).
--
-- Плагин лежит в подкаталоге репозитория, поэтому lazy не может поставить его напрямую.
-- Порядок поиска: $NEON_DIR → типичные места локального клона → клон с GitHub (через lazy).

local sub = "/editors/nvim"

-- Filetype регистрируем явно, не полагаясь на ftdetect плагина: он лежит в подкаталоге и
-- не виден Neovim до загрузки плагина, а плагин грузится только по FileType (замкнутый круг).
vim.filetype.add({ extension = { neon = "neon" } })

local function find_local()
    local candidates = { vim.env.NEON_DIR }
    for _, d in ipairs({ "src", "projects", "dev", "code", "git", "repos", "Projects", "Documents", "" }) do
        table.insert(candidates, "~/" .. (d ~= "" and d .. "/" or "") .. "neon")
    end
    for _, c in ipairs(candidates) do
        if c and c ~= "" then
            local path = vim.fn.expand(c)
            if (vim.uv or vim.loop).fs_stat(path .. sub .. "/lua/neon/init.lua") then
                return path .. sub
            end
        end
    end
end

local opts = {
    -- cmd = { "/home/me/.cargo/bin/neon", "lsp" },  -- если neon не в $PATH
    keymaps = true, -- gd, gr, K, <leader>rn, <leader>ds, <C-s> (в insert)
}

local function setup(_, o) require("neon").setup(o) end

local dir = find_local()
if dir then
    return {
        { dir = dir, name = "neon.nvim", ft = "neon", opts = opts, config = setup },
    }
end

-- Локального клона не нашли: берём репозиторий с GitHub, подкаталог добавляем в rtp вручную
return {
    {
        "bandiwor/neon",
        name = "neon.nvim",
        ft = "neon",
        init = function(plugin)
            vim.opt.rtp:append(plugin.dir .. sub)
        end,
        opts = opts,
        config = setup,
    },
}
