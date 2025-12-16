local M = {}

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")

---@param reg string
M.edit_macro = function(reg)
    local content = fn.getreg(reg, 1, true) ---@cast content string[] with list=true
    local buf = api.nvim_create_buf(false, true)
    local keys = fn.keytrans(table.concat(content, "\n")):gsub("<Space>", " ")
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
                local keycodes = vim.keycode(table.concat(lines, ""))
                fn.setreg(reg, keycodes)
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

return M
