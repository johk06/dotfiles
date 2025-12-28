local M = {}

---@return string
M.get_project_root = function()
    local root
    local clients = vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf() }
    if #clients == 0 then
        clients = vim.lsp.get_clients {}
    end
    if #clients > 0 then
        root = clients[1].root_dir
    end

    if not root then
        root = vim.fs.root(vim.fn.getcwd(0), { ".git", "Makefile" })
    end

    return root or vim.fn.getcwd()
end

return M
