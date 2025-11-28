Jhk.require_program("lua-language-server")

---@type vim.lsp.Config
return {
    filetypes = { "lua" },
    cmd = { "lua-language-server" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
    settings = {
        Lua = {
            semantic = {}
        }
    },
    on_init = function(client)
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
        if vim.g.is_neovim or is_in_rtp then
            version = "LuaJIT"
            -- load nvim-specific libraries only for config
            local nvim_libs = {
                vim.env.VIMRUNTIME, -- runtime files
                vim.fn.stdpath("config") .. "/lua"
            }

            -- load lazy plugins for those that do use lua
            for _, plug in pairs(require("lazy").plugins()) do
                local dir = plug.dir .. "/lua"
                if vim.uv.fs_stat(dir) then
                    table.insert(nvim_libs, dir)
                end
            end

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
