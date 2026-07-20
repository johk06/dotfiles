Jhk.require_program("tinymist")

---@type vim.lsp.Config
return {
    filetypes = { "typst" },
    cmd = { "tinymist" },
    root_markers = { ".git", "typst.toml" },
    settings = vim.g.typst_settings
}
