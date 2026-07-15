#!/usr/bin/env luajit

local win = require("window")
local tablet = require("tablet")
---@type uv
local uv = require("luv")

_G.tablet = tablet

local t = tablet.Tablet.new {
    path = arg[1],
    on_popup = win.show,
    on_popup_close = win.close,
    on_key = win.on_key
}

t:monitor_events()

local gtk_idle = assert(uv.new_prepare())
gtk_idle:start(win.run_gtk)
win.run_gtk()

uv.run()
