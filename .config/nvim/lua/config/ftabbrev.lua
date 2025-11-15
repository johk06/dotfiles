local api = vim.api
local ns = api.nvim_create_namespace("config.ftabbrev")

local M = {}

---@type table<integer, table<string, string>>
M.for_buffers = {}

---@param abbreviations table<string, string>
M.abbreviate = function(abbreviations)
    M.for_buffers[api.nvim_get_current_buf()] = abbreviations
end

local CTRL_Z = vim.keycode "<C-z>"
local BACKSPACE = vim.keycode "<C-h>"
local lastchar
M.setup = function()
    vim.on_key(function(key, typed)
        if typed == CTRL_Z then
            local buf = api.nvim_get_current_buf()
            local abbrevs = M.for_buffers[buf]
            if not abbrevs then
                return
            end
            if not abbrevs[lastchar] then
                return
            end

            local abbrev = abbrevs[lastchar]
            api.nvim_feedkeys(BACKSPACE, "n", false)
            vim.schedule(function()
                vim.snippet.expand(abbrev)
            end)

            return ""
        end
        lastchar = typed
    end, ns)
end

return M
