local M = {}

local operators = require("config.lib.operators")
local utils = require("config.utils")

local verify_to_specifier = function(converter, allowed, to)
    if not allowed:find(to, 1, true) then
        utils.error("Convert/" .. converter, "Supported formats to convert to: " .. allowed)
        return false
    end
    return true
end

local verify_one_line = function(converter, text)
    if #text > 1 then
        utils.error("Convert/" .. converter, "Only single lines supported")
        return false
    end
    return true
end

---@alias config.op.converter fun(text: string[], kind: string, to: string): string[]?

-- Colors {{{
---@type config.op.converter
local colors = function(text, kind, to)
    if not verify_one_line("Color", text) then
        return
    end

    if not verify_to_specifier("Color", "rRhH", to) then
        return
    end

    local parsed
    local color = text[1]
    do
        local rgb_r, rgb_g, rgb_b = color:match("(%d+)[, ](%d+)[, ](%d+)")
        if rgb_g then
            parsed = { tonumber(rgb_r), tonumber(rgb_g), tonumber(rgb_b) }
        end
    end

    if not parsed then
        local r, g, b = color:match("#?(%x%x)(%x%x)(%x%x)")
        if b then
            parsed = { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), a and tonumber(a, 16) }
        end
    end

    if not parsed then
        utils.error("Convert/Color", "Failed to parse as color")
        return
    end

    local out
    if to == "h" then
        out = { ("#%X%X%X"):format(parsed[1], parsed[2], parsed[3]) }
    elseif to == "H" then
        out = { ("%X%X%X"):format(parsed[1], parsed[2], parsed[3]) }
    elseif to == "r" then
        out = { ("rgb(%d, %d, %d)"):format(parsed[1], parsed[2], parsed[3]) }
    elseif to == "R" then
        out = { ("%d %d %d"):format(parsed[1], parsed[2], parsed[3]) }
    end

    return out
end
-- }}}

-- Number Formats {{{
---@type config.op.converter
local numbers = function(text, kind, to)
    if not verify_one_line("Number", to) then
        return
    end

    if not verify_to_specifier("Number", "bdxXorR", to) then
        return
    end

    local parsed = tonumber(text[1])
    if not parsed then
        utils.error("Convert/Number", "Failed to parse number")
        return
    end

    if to == "r" or to == "R" then
        return { utils.format_roman(parsed, to == "R") }
    elseif to == "b" then
        return { utils.format_bin(parsed) }
    else
        -- doxX
        return { ("%" .. to):format(parsed) }
    end
end
-- }}}

---@type table<string, config.op.converter>
M.converters = {
    c = colors,
    n = numbers
}

---@type config.op.operator_func
M.operator = function(mode, region, extra)
    if not extra.repeated then
        extra.saved.kind = vim.fn.getcharstr()
        extra.saved.to = vim.fn.getcharstr()
    end

    local kind = extra.saved.kind
    local to = extra.saved.to

    local converter = M.converters[kind]
    if not converter then
        utils.error(
            "Convert",
            ("No converter for type '%s', try one of %s")
            :format(kind, table.concat(vim.tbl_keys(M.converters))))
        return
    end


    local text = operators.get_region(mode, region)
    local replacement = converter(text, kind, to)
    if replacement then
        operators.set_region(mode, region, replacement)
    end
end


return M
