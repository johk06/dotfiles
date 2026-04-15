---@type zpack.Spec
local M = {
    "kylechui/nvim-surround",
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

local foldmarker = {
    add = function()
        local fdm = vim.opt.foldmarker:get()
        local comment = vim.o.commentstring
        local title = require("nvim-surround.config").get_input("Title: ")
        if not title then
            return
        end

        local opening = comment:format(title .. " " .. fdm[1])
        local closing = comment:format(fdm[2])

        return {
            { opening, "" },
            { "",      closing }
        }
    end,
}

M.opts = {
    surrounds = {
        -- variable expansion
        v = generic_pair("${", "}"),
        -- subshell expansion
        x = generic_pair("$(", ")"),
        -- general associative array key
        k = generic_pair('["', '"]'),
        z = foldmarker
    },
    aliases = {
        -- mirror the {a,i}m textobject (which aliases {i,a}%)
        m = { "}", "]", ")", ">", '"', "'", "`" }
    }
}

return M
