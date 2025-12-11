local M = {}

function M.load()
    package.loaded["theme.groups"] = nil
    local groups = require("theme.groups")
    for name, group in pairs(groups) do
        vim.api.nvim_set_hl(0, name, group)
    end
end

return M
