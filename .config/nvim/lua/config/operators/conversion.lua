local M = {}

local operators = require("config.lib.operators")
local utils = require("config.utils")
local ui = require("config.lib.ui")

---@alias config.op.conversion_normalize fun(from: string, text: string[]): any?

---@class config.op.conversion_menu
---@field menu config.ui.select_item[]
---@field normalize fun(from: string, text: string[]): any?, string?
---@field on_done fun(to: string, value: any): string[]?
---@field name string

-- Colors {{{
---@type config.op.conversion_menu
local colors = {
    name = "Color",
    menu = {
        { key = "r", desc = "RGB" },
        { key = "a", desc = "RGBA" },
        { key = "x", desc = "Hex" },
        { key = "X", desc = "Hex, big" },
        { key = "p", desc = "plain RGB" },
        { key = "P", desc = "plain RGBA" },
    },
    normalize = function(from, _text)
        local text = _text[1]
        if text:sub(1, 1) == "#" then
            local digits = { text:match("#(%x%x)(%x%x)(%x%x)(%x?%x?)") }
            if not digits then
                return "Not a valid hex color"
            end
            return {
                tonumber(digits[1], 16),
                tonumber(digits[2], 16),
                tonumber(digits[3], 16),
                (tonumber(digits[4], 16) or 255) / 255,
            }
        elseif text:match("^rgba?") then
            local digits = { text:match("^rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,?%s*([%d.]*)%s*%)")}
            return vim.tbl_map(tonumber, digits)
        end
    end,
    on_done = function(to, value)
        if to == "x" then
            return { ("#%x%x%x"):format(value[1], value[2], value[3]) }
        elseif to == "X" then
            return { ("#%X%X%X"):format(value[1], value[2], value[3]) }
        elseif to == "p" then
            return { ("%d %d %d"):format(value[1], value[2], value[3]) }
        elseif to == "P" then
            return { ("%d %d %d %.2f"):format(value[1], value[2], value[3], value[4]) }
        elseif to == "r" then
            return { ("rgb(%d, %d, %d)"):format(value[1], value[2], value[3]) }
        elseif to == "a" then
            return { ("rgb(%d, %d, %d, %.2f)"):format(value[1], value[2], value[3], value[4]) }
        end

        vim.print(value)
    end
}
-- }}}

---@type config.op.operator_func
M.operator = function(mode, region, extra)
    local menu, action
    if extra.repeated then
        menu = extra.saved.menu
        action = extra.saved.action
    end

    if not menu then
        menu = ui.select("Convert", {
            { key = "c", desc = "Color",  value = colors },
            { key = "n", desc = "Number", value = "n" },
            { key = "d", desc = "Date",   value = "d" }
        })
    end

    if menu then
        ---@cast menu config.op.conversion_menu
        local name = "Convert/" .. menu.name
        if not action then
            action = ui.select(name, menu.menu)
            if not action then
                return
            end
        end

        local val, err = menu.normalize("", operators.get_region(mode, region))
        if not val then
            utils.warn(name, assert(err))
            return
        end
        local replacement = menu.on_done(action, val)
        if replacement then
            operators.set_region(mode, region, replacement)
        end

        extra.saved.menu = menu
        extra.saved.action = action
    end
end


return M
