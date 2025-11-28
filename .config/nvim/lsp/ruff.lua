Jhk.require_program("ruff")

---@type vim.lsp.Config
return {
    filetypes = { "python" },
    cmd = { "ruff", "server" },
    root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml" }
}
