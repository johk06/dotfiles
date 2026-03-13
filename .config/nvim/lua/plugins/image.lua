---@type LazySpec
local M = {
    "3rd/image.nvim",
    rocks = {
        "magick"
    },
    lazy = true,
    ft = { "markdown", "typst", "html", "neorg", "typst", "org" },
    opts = {
        processor = "magick_rock",
        -- window_overlap_clear_enabled = true,
        window_overlap_clear_ft_ignore = {},
        max_width = 80,
        max_height = 4,
        hijack_file_patterns = {},
        integrations = {
            markdown = {
                -- do not show them by default
                enabled = false,
            },
            org = {
                enabled = true
            },
            typst = {
                enabled = false
            }
        }
    }
}

return M
