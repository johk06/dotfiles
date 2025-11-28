Jhk.require_program("yaml-language-server")

---@type vim.lsp.Config
return {
    filetypes = { "yaml" },
    cmd = { "yaml-language-server", "--stdio" },
    root_markers = { ".git" },
    settings = {
        redhat = {
            telemetry = {
                enabled = false
            }
        }
    },
    on_init = require("config.lsp").lazy_schemastore("yaml"),
}
