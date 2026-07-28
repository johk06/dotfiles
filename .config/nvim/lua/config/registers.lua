local M = {}

local fn = vim.fn
local api = vim.api
local utils = require("config.utils")

---@param s string
---@param reg string
local set_from_str = function(s, reg)
    local text = s:gsub("%s*", "")
    local keycodes = vim.keycode(text):gsub("<Ignore>", "")
    fn.setreg(reg, keycodes)
end

local get_macro_str = function(reg)
    local content = fn.getreg(reg, 1, true) ---@cast content string[] with list=true
    return fn.keytrans(table.concat(content, "\n"))
end

M.MACRO_SAVEPATH = fn.stdpath("config") .. "/saved-macros.json"

---@param reg string
M.edit_macro = function(reg)
    local keys = get_macro_str(reg)
    vim.ui.input({
        prompt = ("Edit @%s"):format(reg),
        default = keys,
    }, function(new)
        if new then
            set_from_str(new, reg)
        end
    end)
end

local macro_cache = {}
local last_load

---@alias config.macro.saved {keys: string, desc: string}

---@return {macros: table<string, config.macro.saved>}
local load_macros = function()
    local time = vim.uv.fs_stat(M.MACRO_SAVEPATH)
    if time and (not last_load or time.mtime.sec ~= last_load) then
        last_load = time.mtime.sec
        local file = io.open(M.MACRO_SAVEPATH, "r")
        if not file then
            macro_cache = {}
        else
            macro_cache = vim.json.decode(file:read("*a"))
            file:close()
        end
    end

    return macro_cache
end

local write_macros = function()
    local as_json = vim.json.encode(macro_cache)
    local file = io.open(M.MACRO_SAVEPATH, "w")
    if not file then
        utils.error("Macros", "Failed to open " .. M.MACRO_SAVEPATH)
        return
    end
    file:write(as_json)
    file:close()
    last_load = vim.uv.fs_stat(M.MACRO_SAVEPATH).mtime.sec
end

M.load_macro = function(reg)
    local macros = load_macros().macros
    vim.ui.select(vim.tbl_keys(macros), {
        prompt = ("Load @%s with"):format(reg),
        format_item = function(macro)
            return ("%s: %s"):format(macro, macros[macro].desc or "")
        end
    }, function(name)
        if not name then
            return
        end

        set_from_str(macros[name].keys, reg)
    end
    )
end

M.save_macro = function(reg)
    local cmds = get_macro_str(reg)
    local macros = load_macros().macros
    vim.ui.input({
        prompt = ("Save @%s as:"):format(reg),
        completion = function()
            return vim.tbl_keys(macros)
        end
    }, function(name)
        if not name or name:match("^%s*$") then
            return
        end
        local ident, _desc = name:match("(%S+)%s*(.*)")
        local desc = _desc:match("(%S.*)")
        local old = macros[ident] or {}
        macros[ident] = vim.tbl_extend("force", old, {
            keys = cmds,
            desc = desc
        })
        write_macros()
    end)
end

M.macro_from_history = function(reg, invoking_length)
    local history = require("config.editor").get_key_history()
    local as_text = fn.keytrans(history:sub(1, -invoking_length))
    vim.ui.input({
        prompt = ("Save to @%s:"):format(reg),
        default = as_text,
    }, function(new)
        if new then
            set_from_str(new, reg)
        end
    end)
end

--[[ Preview {{{
   Show a popup containing registers, their short contents and some other stuff
   when I press " or i_<C-r>.
]]
local ns = api.nvim_create_namespace("config.register")
local register_buf, register_win

local contains_control_char = function(s)
    for i = 1, math.min(#s, 16) do
        local chr = string.byte(s, i)
        if (chr < 32 or chr == 127) and (chr ~= 9 and chr ~= 10 and chr ~= 13) then
            return true
        end
    end
    return false
end

---@param reg string
---@param content string
local classify_reg = function(reg, content)
    if #content == 0 then
        return "empty", { ("%s"):format(reg), "Identifier" }
    elseif contains_control_char(content) then
        return "macro", { reg, "RegisterMacro" }
    elseif reg:match("%d") then
        return "number", { reg, "Number" }
    elseif reg == "+" or reg == "*" or reg == "-" then
        return "special", { reg, "SpecialChar" }
    end
    return "reg", { reg, "String" }
end

local shorten = function(s)
    return vim.trim(s):gsub("%s+", " ")
end

local assemble_lines = function(width, ch, lookup, lines)
    local out = {}
    local per_line = math.floor(#ch / lines)
    local tgt = math.floor(((width - per_line) / per_line))
    for i = 1, lines do
        local line = {}
        for j = 1, per_line do
            local idx = (i - 1) * per_line + j
            local chunk = ch[idx]
            if not chunk then
                break
            end

            local text = shorten(lookup[chunk[1]])
            local textwidth = fn.strdisplaywidth(text)
            local slice_at = math.min(textwidth, tgt)
            local charpos = vim.str_utf_pos(text)[slice_at]

            table.insert(line, chunk)
            table.insert(line, {
                (text:sub(1, charpos)) .. (" "):rep(tgt - textwidth),
                "NonText"
            })
        end
        table.insert(out, line)
    end

    return out
end

local get_register_icons = function(target_width)
    local regs = "abcdefghiklmnopqrstuvwxyz0123456789"

    local output = {
        empty = {},
        macro = {},
        reg = {},
        number = {},
        special = {}
    }
    local texts = {}
    for i = 1, #regs do
        local r = regs:sub(i, i)
        local content = fn.getreg(r)
        local field, chunk = classify_reg(r, content)
        table.insert(output[field], chunk)
        if field == "reg" or field == "number" then
            texts[r] = content
        end
    end

    output.reg = assemble_lines(target_width, output.reg, texts, 2)
    output.number = assemble_lines(target_width, output.number, texts, 2)
    output.special = assemble_lines(target_width, { { "+", "SpecialChar" }, { "*", "SpecialChar" } }, {
        ["*"] = fn.getreg("*"),
        ["+"] = fn.getreg("+")
    }, 1)
    output.unnamed = assemble_lines(target_width, { { '"', "SpecialChar" }, { "-", "SpecialChar" } }, {
        ['"'] = fn.getreg('"'),
        ["-"] = fn.getreg("-")
    }, 1)

    return output
end

local empty_lines = function(n)
    local ret = {}

    for i = 1, n do
        ret[i] = ""
    end

    return ret
end

local show_registers = function()
    if register_buf then
        return
    end
    register_buf = api.nvim_create_buf(false, true)
    local width = math.min(math.floor(vim.o.columns / 2), 60)
    local regs = get_register_icons(width)
    local first_line = vim.list_extend({
        { "->",                         "NonText" },
        { fn.getreginfo('"').points_to, "SpecialChar" },
        { " " }
    }, regs.empty)
    vim.list_extend(first_line, regs.macro)
    local lines = {
        first_line,
    }
    vim.list_extend(lines, regs.unnamed)
    vim.list_extend(lines, regs.special)
    vim.list_extend(lines, regs.number)
    vim.list_extend(lines, regs.reg)
    api.nvim_buf_set_lines(register_buf, 0, 0, false, empty_lines(#lines))
    for i, line in ipairs(lines) do
        api.nvim_buf_set_extmark(register_buf, ns, i - 1, 0, {
            virt_text = line
        })
    end
    register_win = api.nvim_open_win(register_buf, false, {
        style = "minimal",
        relative = "cursor",
        anchor = "NW",
        width = width,
        zindex = 200,
        height = #lines,
        col = 0,
        row = 1,
    })
end
local hide_registers = function()
    if register_win then
        api.nvim_win_close(register_win, true)
    end
    if register_buf then
        api.nvim_buf_delete(register_buf, { force = true })
    end
    register_buf = nil
    register_win = nil
end

M.preview_on_key = function(key)
    api.nvim_feedkeys(key, "n")
    show_registers()
    vim.on_key(vim.schedule_wrap(function()
        hide_registers()
        vim.on_key(nil, ns)
    end), ns)
end

M.clear_register = function()
    fn.setreg(vim.v.register, "")
end

M.clear_all_registers = function()
    for c = 0x61, 0x7a do
        fn.setreg(string.char(c), "")
    end
end
-- }}}

return M
