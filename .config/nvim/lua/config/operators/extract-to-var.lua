local M = {}

local api = vim.api
local utils = require("config.utils")
local operators = require("config.lib.operators")
local ns = api.nvim_create_namespace("config.ui.extract-to-var")

---@type string[]|nil
local last_text = nil
---@type string
local last_register = nil
---@type "expression"|"region"
local next_phase = "expression"
---@type TSNode
local last_node

local sh_name_transformer = function(name, value)
    if value[1]:find([=[["\\]]=]) then
        return ('"$%s"'):format(name)
    end
    return ('${%s}'):format(name)
end

local sh_assignment_generator = function(name, value)
    value[1] = ("%s=%s"):format(name, value[1])
    return value
end

---@type table<string, fun(name: string, value: string[]): string[]?>
M.assignment_generators = {
    lua = function(name, value)
        local valstart = vim.trim(value[1])

        -- table assignment does not need or use the local keyword
        if name:find("%.") or name:find("%[") then
            value[1] = ("%s = %s"):format(name, valstart)
            return value
        end

        value[1] = ("local %s = %s"):format(name, valstart)
        return value
    end,
    bash = sh_assignment_generator,
    sh = sh_assignment_generator,
}

---@type table<string, fun(name: string, value: string[]): string>
M.name_transformers = {
    bash = sh_name_transformer,
    sh = sh_name_transformer
}

---@param region config.region
---@return Range4
local vrange_to_trange = function(region)
    return {
        region[1][1] - 1, region[1][2],
        region[2][1] - 1, region[2][2]
    }
end

---@param region Range4
local node_for_region = function(region)
    return vim.treesitter.get_parser(0):node_for_range(region)
end

---@param node TSNode
---@return string
---@return ([string, string])[]
local serialize_node = function(node)
    local ret = {}
    for n, f in node:iter_children() do
        table.insert(ret, {
            f, vim.treesitter.get_node_text(n, 0)
        })
    end

    return node:type(), ret
end

---@param n1 ([string, string])[]
---@param n2 ([string, string])[]
---@return boolean
local compare_serial_nodes = function(n1, n2)
    if #n1 ~= #n2 then
        return false
    end

    for i = 1, #n1 do
        if n1[i][1] ~= n2[i][1] or n1[i][2] ~= n2[i][2] then
            return false
        end
    end

    return true
end

---@param type string
---@param needle ([string, string])[]
---@param haystack TSNode
---@param dest TSNode[]
---@param range Range4
local function find_matching_nodes(type, needle, haystack, dest, range)
    for n, f in haystack:iter_children() do
        local t, s = serialize_node(n)
        if t == type and compare_serial_nodes(s, needle) then
            if vim.treesitter._range.contains(range, { n:range() }) then
                table.insert(dest, n)
            end
        else
            find_matching_nodes(type, needle, n, dest, range)
        end
    end
end

---@param needle TSNode
---@param haystack TSNode
---@param range Range4
---@return TSNode[]
local find_nodes_inside_node = function(needle, haystack, range)
    local t, s = serialize_node(needle)
    local dest = {}
    find_matching_nodes(t, s, haystack, dest, range)
    return dest
end

---@type config.op.operator_func
local region_selection = function(mode, region, extra)
    next_phase = "expression"
    if not last_text then
        return
    end
    local text = last_text

    region[1][2] = 0
    region[2][2] = #api.nvim_buf_get_lines(0, region[2][1] - 1, region[2][1], false)[1]
    local range = vrange_to_trange(region)
    local containing_node = node_for_region(range)
    local nodes = find_nodes_inside_node(last_node, containing_node, range)

    local ft = vim.bo.ft
    local name = vim.fn.input("Name: ")
    local variable = name
    if M.name_transformers[ft] then
        variable = M.name_transformers[ft](name, text)
    end

    for _, node in ipairs(nodes) do
        local srow, scol, erow, ecol = node:range()
        api.nvim_buf_set_text(0, srow, scol, erow, ecol, { variable })
    end

    if M.assignment_generators[ft] then
        vim.fn.setreg(last_register, M.assignment_generators[ft](name, last_text))
    else
        utils.warn("Extract", ("No assignment generator for '%s'"):format(ft))
    end
end

---@type config.op.operator_func
local expression_selection = function(mode, region, extra)
    local expr_node = node_for_region(vrange_to_trange(region))
    if not expr_node then
        return
    end
    last_node = expr_node
    next_phase = "region"
    last_register = vim.v.register
    last_text = operators.get_region(mode, region)

    local win_start, win_end = vim.fn.getpos("w0"), vim.fn.getpos("w$")
    local range = vrange_to_trange {
        { win_start[2], win_start[3] },
        { win_end[2],   win_end[3] }
    }
    local nodes = find_nodes_inside_node(last_node, node_for_region(range), range)

    for _, node in ipairs(nodes) do
        local srow, scol, erow, ecol = node:range()
        api.nvim_buf_set_extmark(0, ns, srow, scol, {
            end_row = erow,
            end_col = ecol,
            hl_group = "Visual",
        })
    end

    api.nvim_feedkeys("g@", "n", false)

    api.nvim_create_autocmd("SafeState", {
        once = true,
        callback = function()
            api.nvim_buf_clear_namespace(0, ns, 0, -1)
        end
    })
end

---@type config.op.operator_func
M.extract_to_variable = function(mode, region, extra)
    if not vim.treesitter.get_parser(0) then
        utils.error("Extract", "Treesitter is required")
        return
    end
    if next_phase == "expression" then
        expression_selection(mode, region, extra)
    else
        region_selection(mode, region, extra)
    end
end

return M
