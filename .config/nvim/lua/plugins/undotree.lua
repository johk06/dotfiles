---@type LazySpec
local M = {
    "mbbill/undotree",
}

M.config = function()
    local utils = require("config.utils")
    utils.map("n", "<space>u", vim.cmd.UndotreeToggle)

    local g = vim.g

    g.undotree_ShortIndicators = true
    g.undotree_WindowLayout = 1
    g.undotree_SetFocusWhenToggle = true
    g.undotree_DiffAutoOpen = true
    g.undotree_HelpLine = false
    g.undotree_TreeNodeShape = "│"
    g.undotree_TreeVertShape = "¦"
    g.undotree_TreeSplitShape = "⟋"
    g.undotree_TreeReturnShape = "⟍"

    Jhk.Undotree_on_win_enter = function()
        vim.wo[0][0].cursorlineopt = "both"
        local buf = vim.api.nvim_get_current_buf()

        -- nicer to switch to
        vim.bo[buf].buflisted = true

        local map = utils.local_mapper(buf)

        map("n", "K", "<plug>UndotreeNextState")
        map("n", "J", "<plug>UndotreePreviousState")

        map("n", "<C-k>", "<plug>UndotreeNextSavedState")
        map("n", "<C-j>", "<plug>UndotreePreviousSavedState")
    end

    -- HACK: I couldn't figure out how to get a funcref from a v:lua call
    -- TODO: Get rid of this vimscript
    vim.cmd [[
    function g:Undotree_CustomMap()
        call v:lua.Jhk.Undotree_on_win_enter()
    endfunction
    ]]
end

return M
