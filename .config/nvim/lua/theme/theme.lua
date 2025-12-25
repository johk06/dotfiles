local M = {}

local cache = {}

function M.load()
    local background = vim.o.background
    local theme = require("theme.colors")
    theme.palettes.default = background == "light"
        and theme.palettes.light
        or theme.palettes.dark
    if not cache[background] then
        package.loaded["theme.groups"] = nil
        cache[background] = require("theme.groups")
    end
    for name, group in pairs(cache[background]) do
        vim.api.nvim_set_hl(0, name, group)
    end
end

return M
