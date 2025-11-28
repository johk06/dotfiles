Jhk.require_program("typescript-language-server")

---@type vim.lsp.Config
return {
    filetypes = { "javascript", "typescript" },
    cmd = { "typescript-language-server", "--stdio" },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
}
