local M = {}

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

function Jhk.opfunc(mode)
    Ctx.funs[Ctx.last](mode)
end

---@alias op_extra {saved: table, repeated: boolean, arg: any}
---@alias config.op.get fun(mode: string?): string[]
---@alias config.op.set fun(range: config.region, replacement: string[])
---@alias config.op.cb fun(mode: string, region: config.region, extra: op_extra, get: config.op.get, set: config.op.set)

---@param name string
---@param cb function
---@param arg any
function M.make_operator(name, cb, arg)
    local function operator(mode)
        local is_repeat = true
        if mode == nil then
            Ctx.last = name
            Ctx.was_repeat[name] = false
            vim.o.operatorfunc = "v:lua.Jhk.opfunc"
            return "g@"
        elseif not Ctx.was_repeat[name] then
            Ctx.was_repeat[name] = true
            is_repeat = false
        end
        local region = get_op_region(mode)
        local function get_content(_mode)
            local m = _mode or mode
            if m == "line" then
                return vim.api.nvim_buf_get_lines(0, region[1][1] - 1, region[2][1], false)
            else
                return vim.api.nvim_buf_get_text(0, region[1][1] - 1, region[1][2], region[2][1] - 1, region[2][2] + 1,
                    {})
            end
        end

        local function set_content(reg, replacement)
            if replacement then
                if mode == "line" then
                    vim.api.nvim_buf_set_lines(0, reg[1][1] - 1, reg[2][1], false, replacement)
                else
                    vim.api.nvim_buf_set_text(0, reg[1][1] - 1, reg[1][2], reg[2][1] - 1, reg[2][2] + 1, replacement)
                end
            end
        end

        if not Ctx.extra_data[name] then
            Ctx.extra_data[name] = {}
        end
        ---@type op_extra
        local extra = {
            saved = Ctx.extra_data[name],
            repeated = is_repeat,
            arg = arg,
        }
        cb(mode, region, extra, get_content, set_content)
    end

    Ctx.funs[name] = operator
    return operator
end

--- Maps a function as a visual and normal mode operator
---@param keys string
---@param cb config.op.cb
---@param opts {normal_only: boolean?, no_repeated: boolean?, desc: string?}?
---@param arg any
function M.map_function(keys, cb, opts, arg)
    opts = opts or {}
    local mapopts = {
        expr = true,
        desc = opts.desc
    }
    local id = keys
    local operator = M.make_operator(id, cb, arg)
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
