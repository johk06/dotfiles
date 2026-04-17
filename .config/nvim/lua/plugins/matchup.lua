--[[ Information {{{
The built in % is slow, switches modes, and is not really repeatable
This is much nicer while also supporting more node types
}}} ]] --

---@type zpack.Spec
local M = {
    "andymass/vim-matchup",
}

M.init = function()
    local g = vim.g
    -- avoid loading matchparen, it is not needed
    g.loaded_matchparen = true
    -- easily gets cluttered for e.g. switch statements and returns

    g.matchup_delim_nomids = 1

    g.matchup_matchpref = {
        -- highlighting everything makes the contents hard to read
        -- also matches how e.g. function declarations are done, not highlighting the name
        xml = { tagnameonly = 1 },
        html = { tagnameonly = 1 },
    }

    g.matchup_matchparen_offscreen = {
        method = "none", -- treesitter context usually shows it
    }
end

return M
