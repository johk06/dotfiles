-- TODO: this seems quite cool, evaluate whether to use it
---@type LazySpec
local M = {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
}

---@type grug.far.OptionsOverride
M.opts = {
    showCompactInputs = true,
    showInputsTopPadding = false,
    showInputsBottomPadding = false,
    folding = {
        enabled = false,
    },
    helpLine = {
        enabled = false,
    },
    icons = {
        enabled = false
    },
    showEngineInfo = false,
    resultLocation = {
        numberLabelPosition = "right_align",
        numberLabelFormat = " %d",
    },
    visualSelectionUsage = "operate-within-range",
    resultsSeparatorLineChar = " ",
    keymaps = {
        refresh = "<localleader>u"
    },
    windowCreationCommand = "Split",
}

M.init = function()
    Jhk.require_program("ast-grep")
    local utils = require("config.utils")
    utils.map({ "n", "x" }, "<space>G", function()
        require("grug-far").open()
    end)
end

return M
