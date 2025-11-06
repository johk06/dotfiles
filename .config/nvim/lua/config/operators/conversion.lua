local M = {}

local operators = require("config.lib.operators")
local utils = require("config.utils")
local ui = require("config.lib.ui")

M.menus = {
}

---@type config.op.operator_func
M.operator = function(mode, region, extra)
    local value = ui.select("Convert", {
        { key = "#", desc = "Hex Color", value = "h" },
        { key = "r", desc = "RGB Color", value = "r" },
        { key = "n", desc = "Number",    value = "n" },
        { key = "d", desc = "Date",      value = "d" }
    })
end


return M
