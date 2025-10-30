-- TODO: evaluate https://github.com/stevearc/resession.nvim
---@type LazySpec
local M = {
    "GnikDroy/projections.nvim",
    branch = "dev",
    keys = {},
}

M.config = function()
    require("projections").setup {
        workspaces = {
            { path = "~/ws/",     patterns = { ".git" } },
            { path = "~/.config", patterns = { ".git", ".luarc.json" } },
        },

        -- ~/.cache is on a tmpfs
        sessions_directory = vim.fn.stdpath("state") .. "/projections/"
    }

    local utils = require("config.utils")
    utils.user_autogroup("config.projections", {
        ProjectionsPostRestoreSession = function(ev)
            local name = vim.api.nvim_buf_get_name(ev.buf)
            if name == "" then
                require("oil").open()
                utils.warn("Project", "Could not find a named buffer, dropping you to Oil")
            end
        end
    })
end

return M
