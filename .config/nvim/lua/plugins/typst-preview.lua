---@type LazySpec
local M = {
    "chomosuke/typst-preview.nvim",
    ft = { "typst" },
    cmd = { "TypstPreview" },
    opts = {
        open_cmd = "launch-or-inside firefox firefox --new-window %s >/dev/null 2>&1",
        dependencies_bin = {
            tinymist = "tinymist", -- use system or mason version
        }
    }
}

return M
