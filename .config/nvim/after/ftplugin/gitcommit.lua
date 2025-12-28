local firstline = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
if firstline:match("^%s*$") then
    local root = require("config.lib.fs").get_project_root()
    vim.snippet.expand(("${1:%s}: $0"):format(vim.fs.basename(root)))
end
