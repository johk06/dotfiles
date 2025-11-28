Jhk.require_program("taplo")

---@type vim.lsp.Config
return {
    filetypes = { "toml" },
    cmd = { "taplo", "lsp", "stdio" },
    root_markers = { ".git" },
}
