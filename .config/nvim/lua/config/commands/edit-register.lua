local M = {}

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")

local set_from_str = function(s, reg)
    fn.setreg(reg, vim.keycode(s))
end

local get_macro_str = function(reg)
    local content = fn.getreg(reg, 1, true) ---@cast content string[] with list=true
    return fn.keytrans(table.concat(content, "\n")):gsub("<Space>", " ")
end

M.MACRO_SAVEPATH = fn.stdpath("config") .. "/saved-macros.json"

---@param reg string
M.edit_macro = function(reg)
    local buf = api.nvim_create_buf(false, true)
    local keys = get_macro_str(reg)
    api.nvim_buf_set_lines(buf, 0, -1, false, { keys })

    api.nvim_buf_set_name(buf, ("[Register: @%s]"):format(reg))

    local win = utils.win_show_buf(buf, {
        position = "float",
        title = "Editing macro @" .. reg
    })

    local bo = vim.bo[buf]
    bo.buftype = "acwrite"
    bo.modified = false
    local augroup
    augroup = utils.autogroup("config.edit-macro." .. reg, {
        BufWriteCmd = {
            buffer = buf,
            callback = function()
                local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
                set_from_str(table.concat(lines, ""))
                bo.modified = false
            end
        },
        BufLeave = {
            buffer = buf,
            callback = function()
                api.nvim_buf_delete(buf, { force = true })
                api.nvim_del_augroup_by_id(augroup)
            end
        }
    })
end

local macro_cache = {}
local last_load

local load_macros = function()
    local time = vim.uv.fs_stat(M.MACRO_SAVEPATH)
    if not last_load or time ~= last_load then
        last_load = time
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
    local macros = load_macros()
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
    vim.ui.input({ prompt = ("Save @%s as:"):format(reg) }, function(name)
        if not name then
            return
        end
        local ident, desc = name:match("(%S)%s*(.*)")
        local macros = load_macros()
        macros[ident] = {
            keys = cmds,
            desc = desc
        }
        write_macros()
    end)
end

return M
