---@type zpack.Spec
local M = {
    url = "https://codeberg.org/andyg/leap.nvim",
}

--[[ Rationale {{{
  Why leap? Aren't traditional motions enough?

  Yes, that's why I mostly use leap for its remote functionality
  This allows me to use it to augment built in textobjects

  The standalone leap in normal mode can still be useful,
  *if* I am just navigating inside a single screen of text
  Otherwise, search or various more powerful (and easier) motions
  are much much less taxing on both my eyes and my hands
}}} ]]

M.config = function()
    local utils = require("config.utils")
    local map = utils.map

    map("n", "S", "<Plug>(leap-from-window)")
    map("n", "s", "<Plug>(leap)")

    -- o_s is taken by surround, this is a surprisingly amazing map
    map("o", "<Space>", "<Plug>(leap-next-to)")

    --[[ Leap Remote
        Much more flexible than the classic remap for every textobject,
        this avoids enumerating all textobjects here.
        No map for visual mode, since r is useful there

        Some examples & use cases:
        - Use this with cx from ./substitute.lua to swap two regions of text
        - Yanking/deleting a region and pasting it at the cursor
        - Quick changes in other regions required by edits at the cursor
        - Fold text using zf, without needing to go near it ]]
    local remote = require("leap.remote")
    map("o", "r", remote.action)

    --[[ [u]sing, this primarily allows for edits to regions that are not visible
        this is usually *not* a replacement for :s
        If the first search result is not the right one, first question your life choices
        (why did you not just move normally...).
        Then, there's <C-g> and <C-t> to move forward and back
        TODO: maybe there's more things that could use the u prefix? ]]
    map("o", "u/", function() remote.action { jumper = "/" } end)
    map("o", "u?", function() remote.action { jumper = "?" } end)

    -- HACK: override colors only after it has been setup
    vim.api.nvim_create_autocmd("User", {
        pattern = "LeapEnter",
        once = true,
        callback = function()
            local theme = require("theme.colors")
            vim.api.nvim_set_hl(0, "LeapLabelDimmed", {
                bg = theme.palettes.default.bg3,
                nocombine = true,
            })
        end
    })
end

return M
