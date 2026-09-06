---@module "swayimg"
---@type swayimg
local S = swayimg

local shescape = function(str)
  return ('"%s"'):format(str:gsub([["]], [[\"]]):gsub("%$", "\\$"))
end

---@param text string
---@param args string?
local copy_clipboard = function(text, args)
  os.execute(("wl-copy %s -- %s"):format(args or "", shescape(text)))
end

-- General Purpose {{{
local toggle_text = function()
  S.text.visible = not S.text.visible
end

local move = function(dir, inc)
  return function()
    local pos = S.viewer.get_position()
    pos[dir] = pos[dir] + inc
    S.viewer.set_abs_position(pos.x, pos.y)
  end
end

local moveabs = function(dir, edge)
  return function()
    local pos = S.viewer.get_position()
    local size = S.get_window_size()
    local eff = edge * size[dir == "x" and "width" or "height"]
    pos[dir] = eff
    S.viewer.set_abs_position(pos.x, pos.y)
  end
end

local scale = function(inc)
  return function()
    S.viewer.set_abs_scale(S.viewer.scale + inc)
  end
end

---@param fn fun(img: swayimg.image)
local on_current = function(fn)
  ---@param where "viewer"|"gallery"
  return function(where)
    local img = S[where].get_image()
    return fn(img)
  end
end

---@param mark boolean?
local mapboth = function(keys, fn, mark)
  mark = mark == nil and true or mark
  S.viewer.on_key(keys, function()
    fn(mark and "viewer" or nil)
  end)
  S.gallery.on_key(keys, function()
    fn(mark and "gallery" or nil)
  end)
end
-- }}}

-- General config {{{
S.mode = "viewer"           -- mode at startup
S.antialiasing = true       -- anti-aliasing
S.decoration = true         -- window title/buttons/borders
S.overlay = false           -- window overlay mode
S.exif_orientation = true   -- image orientation by EXIF
S.dnd_button = "MouseRight" -- drag-and-drop mouse button
-- }}}
-- Colors {{{
local color = function(sub, name, col)
  S[sub]["set_" .. name](col)
end
color("gallery", "window_color", 0xff2e3440)
color("gallery", "selected_color", 0xffeceff4)
color("gallery", "unselected_color", 0xffeceff4)
color("gallery", "border_color", 0xff8fbcbb)
color("viewer", "mark_color", 0xff808080)
color("viewer", "window_background", 0xff2e3440)
color("text", "shadow", 0x0d000000)
color("text", "background", 0xcc2e3440)
color("text", "foreground", 0xffeceff4)
S.viewer.set_image_chessboard(20, 0xff333333, 0xff4c4c4c)
-- }}}

-- Format specific parameters
S.set_format_params('raw', { camera_wb = true }) -- use camera white balance

-- Gallery {{{
S.imagelist.order = "numeric" -- list order
S.imagelist.reverse = false   -- reverse order
S.imagelist.recursive = true  -- recursive directory reading
S.imagelist.adjacent = false  -- add adjacent files from same dir
S.imagelist.fsmon = true      -- enable file system monitoring
-- }}}
-- Text {{{
S.text.font = "Fira Code" -- font name
S.text.size = 16          -- font size in pixels
S.text.spacing = 0        -- line spacing
S.text.padding = 10       -- padding from window edge
S.text.timeout = 5        -- layer hide timeout
S.text.status_timeout = 3 -- status message hide timeout
-- }}}
-- Viewer {{{
S.viewer.default_scale = "optimal"   -- default image scale
S.viewer.default_position = "center" -- default image position
S.viewer.drag_button = "MouseLeft"   -- mouse button to drag image
S.viewer.autocenter = true           -- enable automatic centering
S.viewer.loop = true                 -- enable image list loop mode
S.viewer.preload = 1                 -- number of images to preload
S.viewer.history = 1                 -- number of the history cache
S.viewer.pinch_factor = 1.0          -- pinch gesture factor
S.viewer.set_text("topleft", {       -- top left text block scheme
  "{name}",
  "Fmt:\t{format}",
  "Size:\t{sizehr}",
  "Date:\t{meta.Exif.Photo.DateTimeOriginal}",
  "Camera:\t{meta.Exif.Image.Model}",
  "Desc:\t{meta.Xmp.dc.description}"
})
S.viewer.set_text("topright", { -- top right text block scheme
  "Idx: {list.index} of {list.total}",
  "Frm: {frame.index} of {frame.total}",
  "Res: {frame.width}×{frame.height}"
})
S.viewer.set_text("bottomleft", { -- bottom left text block scheme
  "Scale: {scale}"
})
S.on_window_resize(function()
  pcall(S.viewer.set_fix_scale, "optimal")
end)
-- }}}

-- The default binds aren't that good
S.viewer.bind_reset()
S.gallery.bind_reset()

local get_scaled_rel = function(x, ix, s)
  return math.floor((x - ix) / s)
end

local get_px_coords = function()
  local cursor = S.get_mouse_pos()
  local relative = S.viewer.get_position()
  local pict = S.viewer.get_image()
  local scale = S.viewer.scale
  local px_x = get_scaled_rel(cursor.x, relative.x, scale)
  local px_y = get_scaled_rel(cursor.y, relative.y, scale)

  if not pict
      or px_x < 0 or px_x > pict.width
      or px_y < 0 or px_y > pict.height then
    return nil
  end
  return { x = px_x, y = px_y }
end

local measurements = {}
local show_coord = function(c)
  return string.format("%d,%d", c.x, c.y)
end
local show_distance = function(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y

  local point = show_coord({ x = dx, y = dy })
  return point .. ("=%.1fpx"):format(math.sqrt(dx * dx + dy * dy))
end
local display_measurements = function()
  local text = {}
  for i, m in ipairs(measurements) do
    local next = measurements[i + 1]
    local txt = show_coord(m)
    if next then
      txt = txt .. " to " .. show_coord(next) .. " : " .. show_distance(m, next)
    end
    table.insert(text, txt)
  end
  S.text.status = table.concat(text, "\n")
end
local measure_image = function()
  local c = get_px_coords()
  if not c then
    return
  end
  table.insert(measurements, c)
  display_measurements()
end

local clear_mesaurement = function()
  measurements = {}
  S.text.status = "[Measurement Cleared]"
end
local set_measurement = function()
  if #measurements > 1 then
    table.remove(measurements)
  end
  measure_image()
end
local drop_measurement = function()
  table.remove(measurements)
  display_measurements()
end

-- Mappings for everywhere {{{
mapboth("q", S.exit, false)
mapboth("w", on_current(function(img)
  os.execute(("wallpaper both %s"):format(shescape(img.path)))
end), true)
mapboth("p", on_current(function(img)
  print(img.path)
end))
-- for null-terminated (e.g. xargs -0)
mapboth("Shift+p", on_current(function(img)
  io.write(img.path .. "\0")
  io.flush()
end))
mapboth("t", toggle_text)
mapboth("y", on_current(function(img)
  copy_clipboard(img.path)
end))
mapboth("Alt+y", on_current(function(img)
  copy_clipboard(img.path, "-p")
end))
-- }}}
-- Viewer Mappings {{{
local mousev = S.viewer.on_mouse
local mapv = S.viewer.on_key
mapv("h", move("x", 32))
mapv("l", move("x", -32))
mapv("k", move("y", 32))
mapv("j", move("y", -32))

mapv("Shift+h", moveabs("x", 0))
mapv("Shift+l", moveabs("x", -1))
mapv("Shift+k", moveabs("y", 0))
mapv("Shift+j", moveabs("y", -1))

mapv("i", scale(0.05))
mapv("o", scale(-0.05))
mapv("Shift+i", scale(0.10))
mapv("Shift+o", scale(-0.10))
mapv("z", function()
  S.viewer.set_fix_scale("optimal")
end)
mapv("Shift+z", function()
  S.viewer.set_fix_scale("width")
end)
mapv("Ctrl+Z", function()
  S.viewer.set_fix_scale("height")
end)

mousev("Ctrl+ScrollUp", function()
  local pos = S.get_mouse_pos()
  local scale = S.viewer.scale
  scale = scale + scale / 10
  S.viewer.set_abs_scale(scale, pos.x, pos.y);
end)
mousev("Ctrl+ScrollDown", function()
  local pos = S.get_mouse_pos()
  local scale = S.viewer.scale
  scale = scale - scale / 10
  S.viewer.set_abs_scale(scale, pos.x, pos.y);
end)
mousev("ScrollUp", move("y", 75))
mousev("ScrollDown", move("y", -75))
mousev("ScrollRight", move("x", -75))
mousev("ScrollLeft", move("x", 75))

mapv("v", function() S.mode = "gallery" end)
mapv("r", function()
  S.viewer.rotate(90)
end)
-- mirror
mapv("m", function()
  S.viewer.rotate(180)
end)

mapv("n", function() S.viewer.open("next") end)
mapv("Shift+n", function() S.viewer.open("prev") end)

mapv("Escape", clear_mesaurement)
mapv("Backspace", drop_measurement)
mousev("Ctrl+MouseLeft", measure_image)
mousev("Ctrl+MouseRight", set_measurement)
-- }}}
-- Gallery Mappings {{{
local mouseg = S.gallery.on_mouse
local mapg = S.gallery.on_key
mapg("Return", function() S.mode = "viewer" end)
mouseg("MouseLeft", function() S.mode = "viewer" end)
for k, dir in pairs {
  h = "left",
  l = "right",
  j = "down",
  k = "up",
  g = "first",
  ["Shift+g"] = "last",
  u = "pgup",
  d = "pgdown",
} do
  mapg(k, function()
    S.gallery.select(dir)
  end)
end
mouseg("ScrollDown", function() S.gallery.select("down") end)
mouseg("ScrollUp", function() S.gallery.select("up") end)
-- }}}

-- Gallery {{{
S.gallery.aspect = "fill"       -- thumbnail aspect ratio
S.gallery.thumb_size = 200      -- thumbnail size in pixels
S.gallery.padding_size = 5      -- padding between thumbnails
S.gallery.border_size = 5       -- border size for selected thumbnail
S.gallery.selected_scale = 1.2  -- scale for selected thumbnail
S.gallery.pinch_factor = 100.0  -- pinch gesture factor
S.gallery.hover = true          -- enable mouse following
S.gallery.cache = 100           -- number of thumbnails stored in memory
S.gallery.embedded_thumb = true -- use embedded thumbnails
S.gallery.preload = false       -- preloading invisible thumbnails
S.gallery.pstore = false        -- enable persistent storage for thumbnails
S.gallery.set_text("topleft", { -- top left text block scheme
  "{name}",
})
S.gallery.set_text("topright", { -- top right text block scheme
  "{list.index} of {list.total}"
})
-- }}}
