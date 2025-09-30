local ensure_installed = {
    "asm",
    "awk",
    "bash",
    "c",
    "comment",
    "cpp",
    "css",
    "gitcommit",
    "jq",
    "json",
    "jsonc",
    "latex",
    "lua",
    "luadoc",
    "luap",
    "mail",
    "markdown",
    "markdown_inline",
    "printf",
    "python",
    "query",
    "regex",
    "scss",
    "vim",
    "vimdoc",
}

local textobjects = {
    -- function declarations
    ["af"] = "@function.outer",
    ["if"] = "@function.inner",
    -- function calls
    ["iF"] = "@call.inner",
    ["aF"] = "@call.outer",
    -- read: inside/around argument
    ["ia"] = "@parameter.inner",
    ["aa"] = "@parameter.outer",
    -- value
    ["iv"] = "@assignment.rhs",
    -- name
    ["in"] = "@assignment.lhs",
    -- comment
    ["ic"] = "@comment.inner",
    ["ac"] = "@comment.outer",
    -- loops
    ["il"] = "@loop.inner",
    ["al"] = "@loop.outer",
    -- conditionals
    ["i?"] = "@conditional.inner",
    ["a?"] = "@conditional.outer",
    -- [k]lasses/structs
    ["ik"] = "@class.inner",
    ["ak"] = "@class.outer",
    -- numbers
    ["i1"] = "@number.inner",

    -- blocks
    ["i<space>"] = "@block.inner",
    ["a<space>"] = "@block.outer",
}
local brackets = {
    goto_next_start = {
        ["]a"] = "@parameter.inner",
        ["]f"] = "@function.outer",
        ["]m"] = "@method.outer",
        ["]C"] = "@comment.outer",
        ["]k"] = "@class.outer",
        ["]v"] = "@assignment.lhs",
        ["]l"] = "@loop.outer",
    },
    goto_previous_start = {
        ["[a"] = "@parameter.inner",
        ["[f"] = "@function.outer",
        ["[m"] = "@method.outer",
        ["[C"] = "@comment.outer",
        ["[k"] = "@class.outer",
        ["[v"] = "@assignment.lhs",
        ["[l"] = "@loop.outer",
    },

    goto_next_end = {
        ["]A"] = "@parameter.inner",
        ["]F"] = "@function.outer",
        ["]M"] = "@method.outer",
    },
    goto_previous_end = {
        ["[A"] = "@parameter.inner",
        ["[F"] = "@function.outer",
        ["[M"] = "@method.outer",
    },
}
local swaps = {
    swap_next = {
        [">,"] = "@parameter.inner",
    },
    swap_previous = {
        ["<,"] = "@parameter.inner",
    }
}

---@type LazyPluginSpec
local ts_texobjects = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    config = function()
        require("nvim-treesitter-textobjects").setup {}
        local utils = require("config.utils")
        local map = utils.map
        local modes = { "n", "x", "o" }

        local ts_obj = require("nvim-treesitter-textobjects.select")
        for keys, capture in pairs(textobjects) do
            map({ "x", "o" }, keys, function()
                ts_obj.select_textobject(capture, "textobjects")
            end)
        end

        local ts_move = require("nvim-treesitter-textobjects.move")
        for direction, mappings in pairs(brackets) do
            for keys, capture in pairs(mappings) do
                map(modes, keys, function()
                    ts_move[direction](capture)
                end)
            end
        end

        local ts_swap = require("nvim-treesitter-textobjects.swap")
        for direction, mappings in pairs(swaps) do
            for keys, capture in pairs(mappings) do
                map("n", keys, function()
                    return ts_swap[direction](capture)
                end)
            end
        end

        -- use the builtin repeat
        local ts_repeat = require("nvim-treesitter-textobjects.repeatable_move")
        map(modes, ";", ts_repeat.repeat_last_move_next)
        map(modes, ",", ts_repeat.repeat_last_move_previous)

        -- additional repeat movements for plugins
        local nd, pd = utils.make_mov_pair(
            function() vim.diagnostic.jump { count = 1, float = false } end,
            function() vim.diagnostic.jump { count = -1, float = false } end
        )
        map(modes, "]d", nd)
        map(modes, "[d", pd)

        for _, severity in ipairs(vim.diagnostic.severity) do
            local nb, pb = utils.make_mov_pair(
                function() vim.diagnostic.jump { count = 1, float = false, severity = severity } end,
                function() vim.diagnostic.jump { count = -1, float = false, severity = severity } end
            )

            local key = severity --[[@as string]]:sub(1, 1):lower()
            map(modes, "]" .. key, nb)
            map(modes, "[" .. key, pb)
        end

        local builtin_brackets = {
            "s", -- spelling errors
            "z", -- folds
        }
        local bracket_with_count = function(command)
            return function()
                local ok, err = pcall(vim.api.nvim_cmd, {
                    cmd = "normal",
                    bang = true,
                    args = { vim.v.count1 .. command }
                }, { output = false })
                if not ok then
                    utils.error("Map/" .. command, err:gsub("^Vim:E%d+:%s*", ""))
                end
            end
        end
        for _, key in pairs(builtin_brackets) do
            local fwd = "]" .. key
            local bwd = "[" .. key
            local nb, pb = utils.make_mov_pair(
                bracket_with_count(fwd),
                bracket_with_count(bwd)
            )
            map(modes, fwd, nb)
            map(modes, bwd, pb)
        end
    end
}

---@type LazyPluginSpec
local ts_context = {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
        enable = true,
        max_lines = 0,
    }
}

---@type LazySpec
local M = {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    dependencies = {
        ts_texobjects,
        ts_context,
    },
}

local attach = function(buf, language)
    if not vim.treesitter.language.add(language) then
        vim.bo[buf].syntax = "ON"
        return false
    end

    vim.treesitter.start(buf, language)
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

    return true
end

M.init = function()
    require("config.utils").user_autogroup("config.treesitter", {
        TSUpdate = function()
            require("nvim-treesitter.parsers").mail = {
                install_info = {
                    url = "https://github.com/stevenxxiu/tree-sitter-mail",
                    queries = "queries",
                    branch = "master",
                },
                filetype = "mail",
            }
        end
    })
    local ts = require("nvim-treesitter")
    ts.install(ensure_installed)

    require("config.utils").autogroup("config.treesitter", {
        FileType = function(ev)
            local buf = ev.buf
            local ft = vim.bo[buf].ft

            local language = vim.treesitter.language.get_lang(ft) or ft
            if not attach(buf, language) then
                ts.install(language):await(function()
                    attach(buf, language)
                end)
            end
        end
    })
end

return M
