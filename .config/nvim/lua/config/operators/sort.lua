local M = {}

local operators = require("config.lib.operators")

---@type config.op.operator_func
M.operator = function(mode, region, extra)
    local text = operators.get_region(mode, region)
    local items
    local comma_separated = #text == 1
    if comma_separated then
        items = vim.split(text[1], ",")
    else
        items = text
    end

    local whites = {}
    local texts = {}
    for _, item in ipairs(items) do
        local leading_white = item:match("^(%s*)")
        local trailing_white = item:match("(%s*)$")
        table.insert(whites, { leading_white, trailing_white })
        table.insert(texts, vim.trim(item))
    end

    table.sort(texts)

    local replacements = {}
    for i, white in ipairs(whites) do
        table.insert(replacements,
            white[1] .. texts[i] .. white[2]
        )
    end

    if comma_separated then
        operators.set_region("char", region, { table.concat(replacements, ",") })
    else
        operators.set_region(mode, region, replacements)
    end
end


return M
