Jhk.require_program("harper-ls")

---@type vim.lsp.Config
return {
    cmd = { "harper-ls", "--stdio" },
    root_markers = { ".git" },
    -- harper-ls is mostly a situational thing, nothing wrong with just using
    -- :LspStart harper
    -- when it's *actually* needed
    filetypes = {},
}
