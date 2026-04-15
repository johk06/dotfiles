--[[ Information {{{
The built in % is slow, switches modes, and is not really repeatable
This is much nicer while also supporting more node types
}}} ]] --

---@type zpack.Spec
local M = {
    "andymass/vim-matchup",
}

M.init = function()
    -- easily gets cluttered for e.g. switch statements and returns
    vim.g.matchup_delim_nomids = 1

    vim.g.matchup_matchpref = {
        -- highlighting everything makes the contents hard to read
        -- also matches how e.g. function declarations are done, not highlighting the name
        xml = { tagnameonly = 1 },
        html = { tagnameonly = 1 },
    }

    vim.g.matchup_matchparen_offscreen = {
        method = "none", -- treesitter context usually shows it
    }
end

return M
