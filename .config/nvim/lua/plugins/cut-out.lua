---@type zpack.Spec
return {
    "johk06/nvim-cut-out",
    ---@type cutout.config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        -- more ergonomic to hit, works well with the yanking nature of the plugin
        keys = "yd",
        on_found = function(matches, _)
            require("config.utils").message("Cut-Out", ("%d matches"):format(#matches))
        end,
    }
}
