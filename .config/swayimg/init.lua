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
  if S.text.visible() then
    S.text.hide()
  else
    S.text.show()
  end
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
    local cur = S.viewer.get_scale()
    S.viewer.set_abs_scale(cur + inc)
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
S.set_mode("viewer")            -- mode at startup
S.enable_antialiasing(true)     -- anti-aliasing
S.enable_decoration(true)       -- window title/buttons/borders
S.enable_overlay(false)         -- window overlay mode
S.enable_exif_orientation(true) -- image orientation by EXIF
S.set_dnd_button("MouseRight")  -- drag-and-drop mouse button
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
S.imagelist.set_order("numeric")   -- list order
S.imagelist.enable_reverse(false)  -- reverse order
S.imagelist.enable_recursive(true) -- recursive directory reading
S.imagelist.enable_adjacent(false) -- add adjacent files from same dir
S.imagelist.enable_fsmon(true)     -- enable file system monitoring
-- }}}
-- Text {{{
S.text.set_font("Fira Code") -- font name
S.text.set_size(16)          -- font size in pixels
S.text.set_spacing(0)        -- line spacing
S.text.set_padding(10)       -- padding from window edge
S.text.set_timeout(5)        -- layer hide timeout
S.text.set_status_timeout(3) -- status message hide timeout
-- }}}
-- Viewer {{{
S.viewer.set_default_scale("optimal")   -- default image scale
S.viewer.set_default_position("center") -- default image position
S.viewer.set_drag_button("MouseLeft")   -- mouse button to drag image
S.viewer.enable_centering(true)         -- enable automatic centering
S.viewer.enable_loop(true)              -- enable image list loop mode
S.viewer.limit_preload(1)               -- number of images to preload
S.viewer.limit_history(1)               -- number of the history cache
S.viewer.set_pinch_factor(1.0)          -- pinch gesture factor
S.viewer.set_text("topleft", {          -- top left text block scheme
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

mousev("ScrollUp", function()
  local pos = S.get_mouse_pos()
  local scale = S.viewer.get_scale()
  scale = scale + scale / 10
  S.viewer.set_abs_scale(scale, pos.x, pos.y);
end)
mousev("ScrollDown", function()
  local pos = S.get_mouse_pos()
  local scale = S.viewer.get_scale()
  scale = scale - scale / 10
  S.viewer.set_abs_scale(scale, pos.x, pos.y);
end)

mapv("v", function() S.set_mode("gallery") end)
mapv("r", function()
  S.viewer.rotate(90)
end)
-- mirror
mapv("m", function()
  S.viewer.rotate(180)
end)

mapv("n", function() S.viewer.switch_image("next") end)
mapv("Shift+n", function() S.viewer.switch_image("prev") end)
mapv("g", function() S.viewer.switch_image("first") end)
mapv("Shift+g", function() S.viewer.switch_image("last") end)
-- }}}
-- Gallery Mappings {{{
local mouseg = S.gallery.on_mouse
local mapg = S.gallery.on_key
mapg("Return", function() S.set_mode("viewer") end)
mouseg("MouseLeft", function() S.set_mode("viewer") end)
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
    S.gallery.switch_image(dir)
  end)
end
-- }}}

-- Gallery {{{
S.gallery.set_aspect("fill")          -- thumbnail aspect ratio
S.gallery.set_thumb_size(200)         -- thumbnail size in pixels
S.gallery.set_padding_size(5)         -- padding between thumbnails
S.gallery.set_border_size(5)          -- border size for selected thumbnail
S.gallery.set_selected_scale(1.2)     -- scale for selected thumbnail
S.gallery.set_pinch_factor(100.0)     -- pinch gesture factor
S.gallery.enable_hover(true)          -- enable mouse following
S.gallery.limit_cache(100)            -- number of thumbnails stored in memory
S.gallery.enable_embedded_thumb(true) -- use embedded thumbnails
S.gallery.enable_preload(false)       -- preloading invisible thumbnails
S.gallery.enable_pstore(false)        -- enable persistent storage for thumbnails
S.gallery.set_text("topleft", {       -- top left text block scheme
  "{name}",
})
S.gallery.set_text("topright", { -- top right text block scheme
  "{list.index} of {list.total}"
})
-- }}}
