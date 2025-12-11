local M = {}

local cache = {}
groups = require("theme.groups")

function M.load()
    local background = vim.o.background
    local theme = require("theme.colors")
    theme.palettes.default = background == "light"
        and theme.palettes.light
        or theme.palettes.dark
    local groups = cache[background] or groups(theme.palettes.default)
    if not groups then
        cache[background] = groups
    end
    for name, group in pairs(groups) do
        vim.api.nvim_set_hl(0, name, group)
    end
end

return M
