---@type LazySpec
local M = {
    "kylechui/nvim-surround",
    event = "VeryLazy"
}

local function generic_pair(left, right)
    local esc_left, esc_right = vim.pesc(left), vim.pesc(right)
    local cdelete = string.format("^(%s)().-(%s)()$", esc_left, esc_right)
    return {
        add = { left, right },
        find = string.format("%s.-%s", esc_left, esc_right),
        delete = cdelete,
        change = {
            target = cdelete
        }
    }
end

M.opts = {
    surrounds = {
        -- variable expansion
        ["v"] = generic_pair("${", "}"),
        -- subshell expansion
        ["x"] = generic_pair("$(", ")"),
        -- general associative array key
        ["k"] = generic_pair('["', '"]'),
    },
    aliases = {
        -- mirror the {a,i}m textobject (which aliases {i,a}%)
        m = { "}", "]", ")", ">", '"', "'", "`"  }
    }
}

return M
