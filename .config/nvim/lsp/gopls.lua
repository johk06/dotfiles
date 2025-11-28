Jhk.require_program("gopls")

---@type vim.lsp.Config
return {
    cmd = { "gopls"},
    filetypes = {"go", "gomod"},
    root_markers = {"go.mod", ".git"}
}
