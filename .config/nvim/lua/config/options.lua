local opt = vim.opt

opt.number = true         -- Номера строк
opt.relativenumber = true -- Относительные номера (удобно для прыжков)
opt.tabstop = 4           -- Таб = 4 пробела
opt.shiftwidth = 4
opt.expandtab = true      -- Превращать табы в пробелы
opt.smartindent = true    -- Умный отступ
opt.wrap = false          -- Не переносить длинные строки
opt.ignorecase = true     -- Игнорировать регистр при поиске...
opt.smartcase = true      -- ...если не введены заглавные
opt.termguicolors = true  -- Поддержка TrueColor
opt.scrolloff = 8         -- Курсор всегда в центре экрана при скролле
opt.updatetime = 250      -- 50 мс — это запись swap и CursorHold каждые 50 мс; 250 заметно легче

-- Настройка отображения ошибок (диагностики)
vim.diagnostic.config({
    virtual_text = true,     -- Показывать текст ошибки прямо в строке
    signs = true,            -- Показывать значки (icons) на полях слева
    update_in_insert = true, -- Обновлять ошибки пока ты печатаешь
    underline = true,        -- Подчеркивать ошибочный код
    severity_sort = true,
})

opt.laststatus = 3
opt.signcolumn = "yes"   -- колонка знаков всегда видна: текст не прыгает при диагностике/git-знаках

opt.clipboard = "unnamedplus"

-- Сохранять историю отмен (undo) даже после закрытия файла
vim.opt.undofile = true

-- Новые сплиты открываются снизу и справа (естественнее)
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Маркер на 80 (или 100) символов, чтобы не писать длинные строки
vim.opt.colorcolumn = "100"  -- совпадает с ColumnLimit в ~/.clang-format

-- Отключение режима мыши (опционально, если хочешь чисто клавиатурный опыт)
-- vim.opt.mouse = ""
