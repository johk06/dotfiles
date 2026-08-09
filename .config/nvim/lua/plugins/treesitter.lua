-- Textobjects {{{
local textobjects = {
    -- function declarations
    ["af"] = "@function.outer",
    ["if"] = "@function.inner",
    -- function calls/[u]sage
    ["iu"] = "@call.inner",
    ["au"] = "@call.outer",
    -- inside/around argument
    ["ia"] = "@parameter.inner",
    ["aa"] = "@parameter.outer",
    -- variable
    ["i="] = "@assignment.lhs",
    ["iv"] = "@assignment.rhs",
    ["av"] = "@assignment.outer",
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
    -- blocks
    ["i<space>"] = "@block.inner",
    ["a<space>"] = "@block.outer",

    -- environments
    ["ie"] = "@environment.inner",
    ["ae"] = "@environment.outer",
}

local brackets = {
    goto_next_start = {
        ["]a"] = "@parameter.inner",
        ["]f"] = "@function.outer",
        ["]k"] = "@class.outer",
        ["]l"] = "@loop.outer",
        ["]m"] = "@method.outer",
        ["]n"] = "@comment.outer",
        ["]u"] = "@call.outer",
        ["]v"] = "@assignment.lhs",
    },
    goto_previous_start = {
        ["[a"] = "@parameter.inner",
        ["[f"] = "@function.outer",
        ["[k"] = "@class.outer",
        ["[l"] = "@loop.outer",
        ["[m"] = "@method.outer",
        ["[n"] = "@comment.outer",
        ["[u"] = "@call.outer",
        ["[v"] = "@assignment.lhs",
    },

    goto_next_end = {
        ["]A"] = "@parameter.inner",
        ["]F"] = "@function.outer",
        ["]M"] = "@method.outer",
        ["]U"] = "@call.outer",
    },
    goto_previous_end = {
        ["[A"] = "@parameter.inner",
        ["[F"] = "@function.outer",
        ["[M"] = "@method.outer",
        ["[U"] = "@call.outer",
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

---@type zpack.Spec
local ts_texobjects = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    config = function()
        require("nvim-treesitter-textobjects").setup {
            select = {
                lookahead = true
            }
        }
        local utils = require("config.utils")
        local map = utils.map
        local modes = utils.mode_motion

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
    end
}

---@type zpack.Spec
local ts_context = {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
        enable = true,
        max_lines = 5,
    }
}
--- }}}

---@type zpack.Spec
local M = {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = function()
        require("nvim-treesitter").update()
    end,
    dependencies = {
        ts_texobjects,
        ts_context,
    },
}

-- Parsers I always want {{{
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

    -- although bundled with neovim, a newer version is often needed
    -- (mainly for compatibility with newer queries)
    "vim",
    "vimdoc",
}
-- }}}

---@param buf integer
---@param language string
local attach = function(buf, language)
    local bo = vim.bo[buf]
    if not vim.treesitter.language.add(language) then
        bo.syntax = "ON"
        return false
    end

    vim.treesitter.start(buf, language)
    if vim.treesitter.query.get(language, "indents") ~= nil then
        bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    -- Treesitter makes sure spell checking is constrained to the relevant parts
    -- So it generally should be fine to enable
    vim.opt_local.spell = true

    return true
end

---@param buf integer
local detach = function(buf)
    local bo = vim.bo[buf]
    vim.treesitter.stop(buf)
end

M.config = function()
    require("config.utils").user_autogroup("config.treesitter.update", {
        TSUpdate = function()
            local ts = package.loaded["nvim-treesitter.parsers"]
            ts.mail = {
                install_info = {
                    url = "https://github.com/stevenxxiu/tree-sitter-mail",
                    queries = "queries",
                    branch = "master",
                },
                filetype = "mail",
            }
            ts.ripe = {
                install_info = {
                    path = "/home/jhk/ws/tree-sitter-ripe/",
                    url = "https://github.com/johk06/tree-sitter-ripe",
                    queries = "queries"
                },
                tier = 2,
                filetype = "ripe"
            }
        end
    })
    local ts = require("nvim-treesitter")
    ts.install(ensure_installed)
    local parsers = require("nvim-treesitter.parsers")

    require("config.utils").autogroup("config.treesitter", {
        FileType = function(ev)
            local buf = ev.buf
            local ft = vim.bo[buf].ft

            local language = vim.treesitter.language.get_lang(ft) or ft
            local attached = attach(buf, language)
            if not attached then
                if parsers[language] then
                    ts.install(language):await(function()
                        attach(buf, language)
                    end)
                else
                    detach(buf)
                end
            end
        end
    })
end

return M
