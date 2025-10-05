---@type LazySpec
local M = {
    "windwp/nvim-autopairs",
}

-- Don't mess up my apostrophes
-- I *will* be sad
local apostrophe_never_paired = {
    "gitcommit",
    "latex",
    "lisp",
    "markdown",
    "org",
    "scheme",
    "text",
    "typst",
}

local double_dollar = {
    "tex",
    "typst"
}

local xml_angles = {
    "html",
    "xml"
}


M.config = function()
    local ap = require("nvim-autopairs")
    local rule = require("nvim-autopairs.rule")
    local cond = require("nvim-autopairs.conds")
    ap.setup {
        map_cr = false
    }

    ap.get_rules("'")[1].not_filetypes = apostrophe_never_paired

    ap.add_rules{
        rule.new("$", "$", double_dollar),
        rule.new("<", ">", xml_angles):with_pair():with_move()
    }
end

return M
