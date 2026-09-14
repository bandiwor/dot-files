return {
    {
        "3rd/image.nvim",
        event = "VeryLazy",
        opts = {
            backend = "kitty", -- Если используешь WezTerm/Ghostty/Kitty. Для других попробуй "ueberzug"
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "markdown", "vimwiki" },
                },
                html = {
                    enabled = true,
                    only_render_image_at_cursor = true, -- Показывать картинку, только когда курсор на ссылке
                },
                css = {
                    enabled = true,
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = nil,
            max_height_window_percentage = 40, -- Картинка займет не больше 40% высоты окна
            window_overlap_clear_enabled = false,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "Noice" },
        },
    }
}
