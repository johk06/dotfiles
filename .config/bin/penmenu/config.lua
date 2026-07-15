local M = {}
local HOME = os.getenv("HOME")

---@type uv
local uv = require("luv")

---@class Action
---@field label string
---@field cb fun(t: Tablet): boolean
---@field class string?
---@field cols integer?

local dotool_in = assert(uv.new_pipe())
---@diagnostic disable-next-line: missing-fields
local dotool = uv.spawn("dotool", {
    stdio = { dotool_in }
}, function(code, signal)

end)

local run = function(cmd, args)
    return function(tablet)
        -- debounce so gtk can handle the key first
        assert(uv.new_timer()):start(0, 0, function()
            cmd = cmd:gsub("^~", HOME)
            uv.spawn(cmd, {
                args = args,
                detached = true,
                cwd = HOME,
            }, function(code, signal)
            end)
        end)
        return true
    end
end

local keys = function(keys)
    return function(tablet)
        assert(uv.new_timer()):start(0, 0, function()
            dotool_in:write(keys .. "\n")
        end)
        return true
    end
end

---@type Action[][]
M.actions = {
    {
        { label = "󰆒", cb = keys [[key ctrl+v]], class = "paste" },
        { label = "", cb = keys [[key ctrl+c]], class = "copy" },
        { label = "", cb = keys [[key ctrl+x]], class = "cut" },
    },
    {
        {
            label = "",
            cb = run("xournalpp", {}),
            class = "write"
        },
        {
            label = "󰨵",
            cb = run("~/.config/sway/scripts/screenshot", { "region", "tmp", "clip" }),
            class = "screenshot"
        },
        { label = "󰕌", cb = keys [[ctrl+z]], class = "undo" }
    },
    {
        { label = "Close", cb = function() return true end, class = "quit", cols = 3 }
    }
}

---@param t Tablet
---@param k Event
M.on_key = function(win, t, k)
    local win_open = win.visible
    if win_open then
        if k.code == tablet.Key.ERASE and k.value == 1 then
            win:hide()
        end
    end
end

return M
