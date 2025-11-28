Jhk.require_program("bash-language-server")

---@type vim.lsp.Config
return {
    filetypes = { "bash", "sh" },
    cmd = { "bash-language-server", "start" },
    root_markers = { ".git" },
}
