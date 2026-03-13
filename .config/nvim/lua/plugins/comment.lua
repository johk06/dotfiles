---@type LazySpec
local M = {
    "numToStr/Comment.nvim",
    lazy = false,
    opts = {},
}

M.config = function()
    require("Comment").setup()
    require("Comment.ft").ripe = {
        "(%s)", "(%s)"
    }
end

return M
