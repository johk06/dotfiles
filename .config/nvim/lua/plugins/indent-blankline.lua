---@type zpack.Spec
local M = {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
}

---@type ibl.config
M.opts = {
    indent = {
        highlight = {
            "IndentBlanklineIndent"
        },
    },
    scope = {
        show_end = false,
        show_start = false,
        highlight = {
            "IndentBlanklineScope",
        },
        include = {
            node_type = {
                lua = {
                    "return_statement",
                    "table_constructor"
                },
            }
        }
    },
    exclude = {
        filetypes = {
            "undotree",
            "blink"
        }
    }
}

return M
