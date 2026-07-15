local lgi = require('lgi')
local Gtk = lgi.require('Gtk', '3.0')
local Gdk = lgi.require('Gdk')
local GtkLayerShell = lgi.require('GtkLayerShell')
local cur_tablet

local cfg = require("config")


local css_provider = Gtk.CssProvider()
assert(css_provider:load_from_path("style.css", 0), "Couldn't load CSS file")
Gtk.StyleContext.add_provider_for_screen(
    Gdk.Display.get_default_screen(Gdk.Display:get_default()),
    css_provider,
    600
)

local M = {}

local win = Gtk.Window()
local fixed = Gtk.Fixed { class = "background" }
win:add(fixed)

GtkLayerShell.init_for_window(win)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, 0)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, 0)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, 0)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, 0)
GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
GtkLayerShell.set_namespace(win, "penmenu")


-- Let uv drive the Gtk event loop
M.run_gtk = function()
    if Gtk.events_pending() then
        Gtk.main_iteration()
    end
    return true
end

local actions = Gtk.Grid { column_spacing = 6, row_spacing = 6 }
actions:get_style_context():add_class("popup")
for i, row in ipairs(cfg.actions) do
    for j, btn in ipairs(row) do
        local button = Gtk.Button {
            label = btn.label,
            on_clicked = function()
                local close = btn.cb(cur_tablet)
                if close then
                    win:hide()
                end
            end
        }
        local sty = button:get_style_context()
        sty:add_class("action-button")
        if btn.class then
            sty:add_class(btn.class)
        end
        actions:attach(button, j, i, btn.cols or 1, 1)
    end
end
fixed:put(actions, 0, 0)

win.on_map = function(self)
    local width, height = self:get_size()
    local x, y = cur_tablet:get_relative_position()

    local relx, rely = math.floor(width * x), math.floor(height * y)
    local req, _ = actions:get_preferred_size()

    -- the requisition is only approximate ofc, but better than nothing
    local adj_x = relx - math.floor(req.width / 2)
    local adj_y = rely - math.floor(req.height / 2)
    fixed:move(actions, adj_x, adj_y)
end

---@param t Tablet
M.show = function(t)
    cur_tablet = t
    win:show_all()
end
---@param t Tablet
M.close = function(t)
    -- win:hide()
    -- print("close")
end

M.on_key = function(t, k)
   cfg.on_key(win,t, k)
end


return M
