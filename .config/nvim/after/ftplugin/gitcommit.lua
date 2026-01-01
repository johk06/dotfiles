local firstline = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
local git_prefix = vim.env.GIT_PREFIX

if firstline:match("^%s*$") then
    local root = git_prefix
        and git_prefix:sub(1, -2)
        or require("config.lib.fs").get_project_root()
    vim.snippet.expand(("${1:%s}: $0"):format(vim.fs.basename(root)))
end
