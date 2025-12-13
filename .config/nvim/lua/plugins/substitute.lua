---@type LazySpec
local M = {
    "gbprod/substitute.nvim",
    config = function()
        local substitute = require("substitute")

        substitute.setup {
            highlight_substituted_text = {
                enabled = false,
            }
        }

        local map = require("config.utils").map

        -- no one cares about the sleep operator...
        map("n", "gs", substitute.operator)
        map("n", "gss", substitute.line)
        map("n", "gS", substitute.eol)
        map("x", "gs", substitute.visual)

        -- ex-change <=> change-ex
        local exchange = require("substitute.exchange")
        map("n", "cx", exchange.operator)
        map("n", "cxx", exchange.line)
        map("x", "X", exchange.visual)
    end
}


return M
