Jhk.require_program("clangd")

--[[ NOTE: Clangd loves to write tons of pre-parsed library files or whatever to /tmp
 (See https://github.com/clangd/clangd/issues/1007)
 That isn't very nice, so create a *special* TMPDIR just for it ]]
local CACHEPATH = vim.fn.stdpath("cache") .. "/clangd"
vim.uv.fs_mkdir(CACHEPATH, 493) -- 0755
local utils = require("config.utils")


---@param client vim.lsp.Client
local goto_header = function(client, cmd)
    local params = vim.lsp.util.make_text_document_params(buf)
    client:request("textDocument/switchSourceHeader", params, function(err, res)
        if err then
            utils.error("Lsp/Clangd", tostring(err))
            return
        end

        if not res then
            utils.error("Lsp/Clangd", "Could not determine header/source for file")
            return
        end

        cmd(vim.uri_to_fname(res))
    end)
end

---@type vim.lsp.Config
return {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    cmd = { "clangd" },
    root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "Makefile", ".git" },
    cmd_env = {
        TMPDIR = CACHEPATH
    },
    on_attach = function(client, buf)
        local map = utils.local_mapper(buf, { group = true })

        -- goto header
        map("n", "<localleader>h", function() goto_header(client, vim.cmd.drop) end,
            { desc = "Lsp/Clangd: Switch between header and source" })
        map("n", "<localleader>H", function() goto_header(client, vim.cmd.Split) end,
            { desc = "Lsp/Clangd: Split header and source" })
    end
}
