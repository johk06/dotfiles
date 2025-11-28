Jhk.require_program("clangd")

---@type vim.lsp.Config
return {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    cmd = { "clangd" },
    root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "Makefile", ".git" },
    on_attach = function(client, buf)
        local utils = require("config.utils")
        local map = utils.local_mapper(buf, { group = true })

        -- goto header
        map("n", "gh", function()
            local params = vim.lsp.util.make_text_document_params(buf)
            client:request("textDocument/switchSourceHeader", params, function(err, res)
                if err then
                    utils.error("Lsp/Clangd", tostring(err))
                    return
                end

                if not res then
                    utils.error("Lsp/Clangd", "Could not determine header/implementation for file")
                    return
                end

                vim.cmd.edit(vim.uri_to_fname(res))
            end)
        end)
    end
}
