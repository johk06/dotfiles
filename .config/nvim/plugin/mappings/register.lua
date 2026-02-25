--[[ Synopsis: Make register operations more consistent {{{
 ]]

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local map = utils.map
-- }}}

-- Use a register specified via the register-prefix, like other builtin commands
-- However: use "q as the default instead of ""
local getmacroreg = function()
    local r = vim.v.register
    return r ~= '"' and r or "q"
end

-- Use C-q to record, it is not that common, q is now free to close windows
map({ "n", "x" }, "<C-q>", function()
    if fn.reg_recording() ~= "" then
        return "q"
    else
        return "q" .. getmacroreg()
    end
end, { expr = true })

-- The alike for @
map({ "n", "x" }, "@", "<nop>")
map({ "n", "x" }, "@", function()
    if api.nvim_get_mode().mode:lower() == "v" then
        return ("\x1b<cmd>'<,'>normal! @%s<cr>"):format(getmacroreg())
    else
        return "@" .. getmacroreg()
    end
end, { expr = true })

-- Perform various manipulations on registers
local register_utils = require("config.registers")

map("n", "cq", function()
    register_utils.edit_macro(getmacroreg())
end, { desc = "Macro: Change" })
map("n", "yq", function()
    register_utils.load_macro(getmacroreg())
end, { desc = "Macro: Load" })
map("n", "dq", function()
    register_utils.save_macro(getmacroreg())
end, { desc = "Macro: Define" })
map("n", ">q", function()
    -- Trim the 3 characters ">q" takes up
    register_utils.macro_from_history(getmacroreg(), 3)
end, { desc = "Macro: From History" })
