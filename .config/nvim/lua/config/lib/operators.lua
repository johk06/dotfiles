local M = {}
local api = vim.api

--[[ Information {{{
Despite being able to add operators to vim, this usually needs to be redone by each plugin
This module adds common code that can be used to create custom operators

make_operator() creates a function that wraps a operator function
map_function() automatically creates the expected keybinds for linewise operation and visual mode
}}} ]]

---global context for the operators of this module
local Ctx = {
    funs = {},
    extra_data = {},
    was_repeat = {},
    last = nil,
    -- HACK: preserve last cursor before going into O-pending mode
    last_cursor = nil,
    last_count = nil,
}

M.Ctx = Ctx

local function get_mark(mark)
    return vim.api.nvim_buf_get_mark(0, mark)
end

local function get_op_region(mode)
    if mode == "visual" then
        return { get_mark "<", get_mark ">" }
    else
        return { get_mark "[", get_mark "]" }
    end
end

M.get_op_region = get_op_region

function Jhk.opfunc(mode)
    Ctx.funs[Ctx.last](mode)
end

---@param mode "char"|"line"
---@param region config.region
M.get_region = function(mode, region)
    if mode == "line" then
        return vim.api.nvim_buf_get_lines(0, region[1][1] - 1, region[2][1], false)
    else
        return vim.api.nvim_buf_get_text(0, region[1][1] - 1, region[1][2], region[2][1] - 1, region[2][2] + 1,
            {})
    end
end

---@param mode "char"|"line"
---@param region config.region
---@param replacement string[]
M.set_region = function(mode, region, replacement)
    if mode == "line" then
        vim.api.nvim_buf_set_lines(0, region[1][1] - 1, region[2][1], false, replacement)
    else
        vim.api.nvim_buf_set_text(0, region[1][1] - 1, region[1][2], region[2][1] - 1, region[2][2] + 1, replacement)
    end
end

---@alias config.op.extra {saved: table, repeated: boolean, args: table, hijacked_count: integer}
---@alias config.op.operator_func fun(mode: string, region: config.region, extra: config.op.extra)

---@param name string
---@param cb config.op.operator_func
---@param extra table
---@param hijack_count boolean
function M.make_operator(name, cb, extra, hijack_count)
    local function operator(mode)
        local is_repeat = true
        if mode == nil then
            Ctx.last = name
            Ctx.was_repeat[name] = false
            vim.o.operatorfunc = "v:lua.Jhk.opfunc"
            if hijack_count then
                Ctx.last_count = vim.v.count
                -- <C-l>
                return "\x0cg@"
            else
                return "g@"
            end
        elseif not Ctx.was_repeat[name] then
            Ctx.was_repeat[name] = true
            is_repeat = false
        end
        local region = get_op_region(mode)

        if not Ctx.extra_data[name] then
            Ctx.extra_data[name] = {}
        end
        ---@type config.op.extra
        local params = {
            saved = Ctx.extra_data[name],
            repeated = is_repeat,
            args = extra,
            hijacked_count = Ctx.last_count,
        }
        cb(mode, region, params)
    end

    Ctx.funs[name] = operator
    return operator
end

--- Maps a function as a visual and normal mode operator
---@param keys string
---@param cb config.op.operator_func
---@param opts {normal_only: boolean?, no_repeated: boolean?, desc: string?, hijack_count: boolean}?
---@param extra any
function M.map_function(keys, cb, opts, extra)
    opts = opts or {}
    local mapopts = {
        expr = true,
        desc = opts.desc
    }
    local id = keys
    local operator = M.make_operator(id, cb, extra, opts.hijack_count)
    -- use last char of string to indicate repeat for one line
    local repeat_char = keys:sub(-1, -1)

    if not opts.normal_only then
        vim.keymap.set("x", keys, operator, mapopts)
    end
    vim.keymap.set("n", keys, operator, mapopts)
    if repeat_char ~= "~" and not opts.no_repeated then
        vim.keymap.set("n", keys .. repeat_char, function()
            operator()
            return "g@Vl"
        end, mapopts)
    end
end

return M
