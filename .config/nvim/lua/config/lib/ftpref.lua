-- maps filetypes to behaviors

---@class config.ftpref
---@field indent_only_above boolean? Only select the above fold delimiter with ai-textobject
---@field toc_indent integer? Depth of indentation to show in ToC(gO)

---@type table<string, config.ftpref>
local F = {
    python = {
        indent_only_above = true,
    },
    markdown = {
        indent_only_above = true,
    },
    asm = {
        indent_only_above = true,
    },
    lisp = {
        indent_only_above = true,
    },
    yuck = {
        indent_only_above = true,
    },
    scheme = {
        indent_only_above = true,
    },
    yaml = {
        indent_only_above = true,
    },
    json = {
        toc_indent = 2,
    },
}

return setmetatable(F, {
    __index = function(t, k)
        return rawget(t, k) or {}
    end
})
