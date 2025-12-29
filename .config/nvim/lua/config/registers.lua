local M = {}

local fn = vim.fn
local utils = require("config.utils")

---@param s string
---@param reg string
local set_from_str = function(s, reg)
    local text = s:gsub("%s", "")
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

M.macro_from_history = function(reg)
    local history = fn.keytrans(require("config.editor").get_key_history())
    vim.ui.input({
        prompt = ("Save to @%s:"):format(reg),
        default = history,
    }, function(new)
        if new then
            set_from_str(new, reg)
        end
    end)
end

return M
