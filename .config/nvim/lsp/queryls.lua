vim.g.query_lint_on = {}
Jhk.require_program("ts_query_ls")

---@type vim.lsp.Config
return {
    name = "queryls",
    filetypes = { "query" },
    cmd = { "ts_query_ls" },
    init_options = {
        parser_install_directories = {
            vim.fn.stdpath("data") .. "/site/parser"
        }
    }
}
