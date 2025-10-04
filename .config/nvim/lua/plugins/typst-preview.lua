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

M.init = function()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "typst",
        callback = function(ev)
            if vim.b[ev.buf].did_preview then
                return
            end

            vim.b[ev.buf].did_preview = true
            vim.cmd.TypstPreview()
        end
    })
end

return M
