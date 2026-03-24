--[[ Information {{{
 Additional global functionality for Neovim

 - The key-history:
   Simply keep a time-based log of the last pressed keys, mainly to put them
   into a macro when there is a need for it.
}}} ]]

local ns = vim.api.nvim_create_namespace("config.editor")
local sb = require("string.buffer")

local M = {}

-- how long to wait until the key history is cleared on the next keystroke
local KEYHIST_TIMEOUT = 2e9 -- 2 seconds

local key_hist = sb.new(4096)
local last_key_time = 0
vim.on_key(function(key, typed)
    local time = vim.uv.hrtime()
    if time - last_key_time > KEYHIST_TIMEOUT then
        key_hist:reset()
    end
    last_key_time = time
    key_hist:put(typed)
end, ns)

M.get_key_history = function()
    return key_hist:tostring()
end

return M
