local M = {}
local util = require("util")
local ioctl = require("ioctls")
local ffi = require("ffi")

---@type uv
local uv = require("luv")

local EvType = util.Enum {
    BTN = 1,
    ABS = 3,
}

---@enum Key
local Key = util.Enum {
    TOUCH = 0x14a,
    PROX = 0x140,
    ERASE = 0x141,
    BUTTON = 0x14b
}
M.Key = Key

ffi.cdef [[
struct timeval {
    long sec;
    long nsec;
};

struct input_event {
    struct timeval time;
    unsigned short type;
    unsigned short code;
    unsigned int value;
};

size_t read(int fd, void* buf, size_t count);
]]

local EVENT_SIZE = assert(ffi.sizeof("struct input_event"))

---@class Event
---@field time {sec: integer, nsec: integer}
---@field type integer
---@field code integer
---@field value integer

---@class Tablet
---@field path string
---@field fd integer
---@field was_elligible boolean
---@field timer uv.uv_timer_t
---@field active table<Key, boolean>
---@field x_max integer
---@field y_max integer
---@field axes table<integer, integer>
---@field on_key fun(t: Tablet, k: Event)
---@field on_popup fun(t: Tablet)
---@field on_popup_close fun(t: Tablet)
local Tablet = {}
Tablet.__index = Tablet
Tablet.__tostring = function(self)
    local keys = {}
    for k, v in pairs(self.active) do
        if v then
            table.insert(keys, Key(k))
        end
    end

    return ("Keys: %s"):format(table.concat(keys, " "))
end

M.Tablet = Tablet

---@class TabletOpts
---@field path string
---@field on_key fun(t: Tablet, k: Event)
---@field on_popup fun(t: Tablet)
---@field on_popup_close fun(t: Tablet)

---@param opts TabletOpts
Tablet.new = function(opts)
    local self = setmetatable({}, Tablet)
    self.path = opts.path
    local fd, err = uv.fs_open(opts.path, "r", 0)
    if not fd then
        error(("Failed to open: %s"):format(err))
    end
    self.fd = fd
    self.active = {}
    self.axes = {}

    self.on_popup = opts.on_popup
    self.on_popup_close = opts.on_popup_close
    self.on_key = opts.on_key

    self.timer = assert(uv.new_timer())
    self.x_max, self.y_max = ioctl.get_axis_range(fd)

    return self
end

---@param buf ffi.cdata*
---@param read integer
Tablet.process_events = function(self, buf, read)
    local off = 0
    while off + EVENT_SIZE <= read do
        ---@type Event
        ---@diagnostic disable-next-line: assign-type-mismatch Intentional cast
        local ev = ffi.cast("struct input_event*", buf + off)
        if ev.type == EvType.BTN then
            self.active[ev.code] = ev.value == 1
            self:handle_delay(ev.code)
            self:on_key(ev)
        elseif ev.type == EvType.ABS then
            self.axes[ev.code] = ev.value
        end

        off = off + EVENT_SIZE
    end
end

Tablet.monitor_events = function(self)
    local buf = ffi.new("char[?]", 1024)

    local poll = assert(uv.new_poll(self.fd))
    poll:start("r", function(err, events)
        local numread = ffi.C.read(self.fd, buf, 1024)
        if numread > 0 then
            self:process_events(buf, numread)
        end
    end)
end

Tablet.get_relative_position = function(self)
    local x = self.axes[0] or 0
    local y = self.axes[1] or 0
    return x / self.x_max, y / self.y_max
end

Tablet.handle_delay = function(self, key)
    local held = self.active
    --[[ The pen hovers above the tablet and the eraser is held ]]
    local elligible = ((held[Key.PROX] and held[Key.BUTTON]) or held[Key.ERASE]) and not held[Key.TOUCH]

    if not elligible then
        uv.timer_stop(self.timer)
        if self.was_elligible and key ~= Key.TOUCH then
            self:on_popup_close()
        end
        self.was_elligible = false
    else
        uv.timer_start(self.timer, 300, 0, function()
            self.was_elligible = true
            self:on_popup()
        end)
    end
end

return M
