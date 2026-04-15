-- only load it for these filetypes
local filetypes = { "css", "scss", "sass", "html" }

---@type zpack.Spec
local M = {
    "catgoose/nvim-colorizer.lua",
    ft = filetypes,
    cmd = { "ColorizerAttachToBuffer", "ColorizerDetachFromBuffer", "ColorizerReloadAllBuffers", "ColorizerToggle" },
    keys = {
        { "<space>ch", "<cmd>ColorizerToggle<cr>", desc = "Highlight color values" },
    },
    opts = {
        filetypes = { "*" },
        user_default_options = {
            RGB = true,
            RRGGBB = true,
            names = false,
            RRGGBBAA = true,
            AARRGGBB = true,
            rgb_fn = true,
            hsl_fn = true,
            css = true,
            css_fn = true,
            mode = "background",
            tailwind = false,
            virtualtext = "",
            always_update = false
        },
        bufftypes = {},
    }
}

return M
