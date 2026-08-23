local buf = vim.api.nvim_get_current_buf()
local map = require("config.utils").ft_mapper()

local fn = vim.fn
map("n", "?", function()
    local winid = fn.bufwinid(buf)
    local isloc = fn.getwininfo(winid)[1].loclist == 1
    local get = fn.getqflist
    local set = fn.setqflist
    if isloc then
        get = function(...) fn.getloclist(winid, ...) end
        set = function(...) fn.setloclist(winid, ...) end
    end

    local kind = fn.getcharstr()
    set(vim.tbl_filter(function(e)
        ---@cast e vim.quickfix.entry
        return e.type:lower() == kind
    end, get()), "u")
end, { desc = "Filter by severity" })
