---@type zpack.Spec
local M = {
    "3rd/image.nvim",
    rocks = { "magick" },
    -- Do not actually load it unless it is needed
    lazy = true,

    -- Despite being disabled by default for a few of those, it makes sense to have the commands be available
    opts = {
        -- Fastest
        processor = "magick_rock",
        window_overlap_clear_ft_ignore = {},

        -- Make them as unobtrusive as possible
        max_width = 80,
        max_height = 4,

        -- Nope, just nope. I can stand a :Open % to get a sane image viewer
        hijack_file_patterns = {},
        integrations = {
            org = { enabled = true },
            typst = { enabled = true },
            markdown = { enabled = true, },
        }
    }
}

-- TODO: adjust when they fix setup lol
M.init = function()
    local utils = require("config.utils")
    utils.map("n", "<space>cp", function()
        local image = require("image")
        if image.is_enabled() then
            image.disable()
        else
            image.enable()
        end
    end, { desc = "Toggle picture previews" })
end

return M
