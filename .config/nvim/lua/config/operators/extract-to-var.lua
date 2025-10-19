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

---@type table<string, fun(name: string, value: string[], node: TSNode): string>
M.name_transformers = {
    lua = function(name, value, node)
        -- tables as function arguments need special care
        if value[1]:find([=[^%s*[{'"]]=]) then
            local parent = node:parent()
            if not parent then goto default end
            local parent_of_parent = parent:parent()
            if not parent_of_parent then goto default end
            if parent_of_parent:type() == "function_call" then
                return ("(%s)"):format(name)
            end
        end

        ::default::
        return name
    end,
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
---@param dest table
local function _serialize_node(node, dest)
    for n, f in node:iter_children() do
        if n:child_count() > 0 then
            local tbl = { f, n:type() }
            table.insert(dest, tbl)
            _serialize_node(n, tbl)
        else
            if f then
                table.insert(dest, {
                    n:type(), vim.treesitter.get_node_text(n, 0)
                })
            end
        end
    end
end

---@param node TSNode
---@return table
local serialize_node = function(node)
    local dest = {}
    _serialize_node(node, dest)
    return dest
end

---@param a any
---@param b any
---@return boolean
local function compare_serial_nodes(a, b)
    if type(a) == "table" and type(b) == "table" then
        if #a ~= #b then
            return false
        end
        for i = 1, #a do
            if not compare_serial_nodes(a[i], b[i]) then
                return false
            end
        end
        return true
    else
        return a == b
    end
end

---@param type string
---@param needle table
---@param haystack TSNode
---@param dest TSNode[]
---@param range Range4
local function find_matching_nodes(type, needle, haystack, dest, range)
    for n, f in haystack:iter_children() do
        local s = serialize_node(n)
        if n:type() == type and compare_serial_nodes(s, needle) then
            ---@diagnostic disable-next-line: missing-fields Lua 5.1 allows for this
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
    local s = serialize_node(needle)
    local dest = {}
    find_matching_nodes(needle:type(), s, haystack, dest, range)
    return dest
end

---@type config.op.operator_func
local region_selection = function(mode, region, extra)
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

    -- avoid disturbing the tree
    for node in vim.iter(nodes):rev() do
        local srow, scol, erow, ecol = node:range()
        local replacement = M.name_transformers[ft]
            and M.name_transformers[ft](name, text, node)
            or name
        api.nvim_buf_set_text(0, srow, scol, erow, ecol, { replacement })
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
            next_phase = "expression"
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
