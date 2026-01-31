---@type LazySpec
local M = {
    "johk06/nvim-eject",
}

M.config = function()
    local eject = require("eject")
    local utils = require("config.utils")
    eject.setup {
        open_win = function(target, buf, range)
            local lcount = range[3] - range[1]

            local win
            if lcount < 4 then
                local columns = vim.o.columns
                local lines = vim.api.nvim_buf_get_lines(target, range[1], range[3] + 1, false)
                local max_len = vim.iter(lines):map(function(s)
                    return #s
                end):fold(math.floor(columns / 6), function(cur, val)
                    return math.max(cur, val)
                end)

                win = vim.api.nvim_open_win(buf, true, {
                    bufpos = { range[1] - 2, range[2] - 1 },
                    style = "minimal",
                    relative = "win",
                    width = math.min(max_len, columns),
                    height = lcount + 1
                })

                vim.wo[win][0].wrap = false
            else
                win = utils.open_window_smart(buf, { enter = true })
            end
            return win
        end
    }

    local map = utils.map
    map("n", "cp", eject.eject_operator)
    map("n", "cP", eject.eject_ts_injection)
end

return M
