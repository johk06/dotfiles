Jhk.require_program("lua-language-server")

---@param client vim.lsp.Client
local is_nvim_file = function(client)
    for buf, _ in pairs(client.attached_buffers) do
        local name = vim.fs.basename(vim.api.nvim_buf_get_name(buf))
        if name == ".nvim.lua" then
            return true
        end
    end
    return false
end

---@type vim.lsp.Config
return {
    filetypes = { "lua" },
    cmd = { "lua-language-server" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
    settings = {
        Lua = {
            hint = {
                -- I disable that by default on the Neovim-side, but sometimes it could be useful
                enable = true
            },
            codeLens = {
                -- The same as the inlay hints applies here pretty much
                enable = true
            },
            semantic = {
                -- The treesitter grammar handles this much better
                annotation = false
            }
        }
    },
    on_init = function(client, init)
        if not client.workspace_folders then
            return
        end

        local path = client.workspace_folders[1].name

        local is_in_rtp = false
        for _, elem in pairs(vim.opt.runtimepath:get()) do
            if vim.startswith(path, elem) then
                is_in_rtp = true
                break
            end
        end

        local version
        local libs = {
            "${3rd}/luv/library"
        }
        if vim.g.is_neovim or is_in_rtp or is_nvim_file(client) then
            version = "LuaJIT"
            -- load nvim-specific libraries only for config
            local nvim_libs = {
                vim.env.VIMRUNTIME,                             -- runtime files
                vim.fn.stdpath("config") .. "/lua",             -- config
                vim.fn.stdpath("data") .. "/site/pack/core/opt" -- packages
            }

            vim.list_extend(libs, nvim_libs)
        end

        require("config.lsp").add_setting(client, "Lua", {
            runtime = {
                -- should hold true for any decent system
                version = version,
                -- prefer plugins over specs
                path = { "?/init.lua", "?.lua" },
                strictPath = true
            },
            workspace = {
                checkThirdParty = false,
                library = libs,
            }
        })
    end
}
