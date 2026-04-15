---@type zpack.Spec
local M = {
    "faergeek/Comment.nvim",
    branch = "nvim-0.12-compatibility",
}

M.config = function()
    require("Comment").setup()
    require("Comment.ft").ripe = {
        "(%s)", "(%s)"
    }
end

return M
