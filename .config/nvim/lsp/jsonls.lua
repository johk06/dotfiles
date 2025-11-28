Jhk.require_program("vscode-json-language-server", "json-lsp")

---@type vim.lsp.Config
return {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    init_options = {
        provideFormatter = true
    },
    root_markers = { ".git" },
    on_init = require("config.lsp").lazy_schemastore("json")
}
