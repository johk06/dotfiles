-- TODO: evaluate https://github.com/stevearc/resession.nvim
---@type zpack.Spec
local M = {
    "GnikDroy/projections.nvim",
    branch = "dev",
}

M.init = function()
    -- Don't save everything
    vim.opt.sessionoptions = {
        "buffers",
        "curdir",
        "tabpages",
        "terminal",
        "winsize",
    }
end

M.config = function()
    require("projections").setup {
        selector_mapping = "<space>P",
        workspaces = {
            { path = "~/ws/",     patterns = { ".git" } },
            { path = "~/ws/uni",  patterns = { ".git" } },
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
                local cwd = vim.fn.getcwd()
                vim.schedule(function()
                    for _, file in ipairs(vim.v.oldfiles) do
                        if vim.startswith(file, cwd) then
                            vim.cmd.edit(file)
                            break
                        end
                    end
                    vim.api.nvim_buf_delete(ev.buf, { force = true })
                end)
            end
        end
    })
end

return M
