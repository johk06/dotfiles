---@type zpack.Spec
local M = {
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
    },
}

local utils = require("config.utils")

local ufo
local function merged_provider(providers)
    return function(bufnr)
        local merged = {}

        for _, provider in ipairs(providers) do
            local ok, folds = pcall(ufo.getFolds, bufnr, provider)
            if ok then
                vim.list_extend(merged, folds or {})
            end
        end

        local ordered = {}
        for i, fold in ipairs(merged) do
            fold.old_i = i
            table.insert(ordered, fold)
        end
        table.sort(ordered, function(a, b)
            return a.startLine < b.startLine
        end)

        --[[ Filter out nodes, that
            - Start on the same line but close earlier than the next node
        ]]
        local final = {}
        for i, fold in ipairs(ordered) do
            local next = ordered[i + 1]
            if next and fold.startLine == next.startLine and fold.endLine < next.endLine
            then
            else
                table.insert(final, fold)
            end
        end

        table.sort(final, function(a, b)
            return a.old_i < b.old_i
        end)


        return #final > 0 and final or nil
    end
end

local marker_start = function()
    return vim.split(vim.wo[0].foldmarker, ",")[1]
end

--- Format the virtual text of a fold
---@param virt_text [string, string][]
---@param row integer
---@param end_row integer
---@param width integer
---@param truncate fun(string, integer): string
---@return table
local function fold_formatter(virt_text, row, end_row, width, truncate, extra)
    local new_text = {}
    local kind = extra.get_fold_kind(row)

    local suffix = {
        { "[",                                    "@punctuation.delimiter", },
        { ("%d Lines"):format(end_row - row + 1), "UfoSuffix" },
        { "]",                                    "@punctuation.delimiter", },
    }

    local suffix_width = 2 + #suffix[2][1]

    -- it's a marked fold, pretty print the marker label and (if it is there) level
    local _, _, title, level = extra.text:find(".-%s+(.-)%s*" .. marker_start() .. "(%d*)")
    if kind == "marker" and title then
        title = title and title:gsub("%s*$", "") or "[-]"
        level = level or ""

        local hlgroup
        if title:find("^Info") or title:find("^Rationale") then
            hlgroup = "UfoFoldInfo"
        elseif title:find("^Config") then
            hlgroup = "UfoFoldConfig"
        elseif title:find("Unused") or title:find("^Other") then
            hlgroup = "UfoFoldHidden"
        elseif title:find("^Util")
            or title:find("^Helper")
            or title:find("^[Dd]ecl")
            or title:find("^[Cc]onst") then
            hlgroup = "UfoFoldUtil"
        else
            hlgroup = "UfoFoldTitle"
        end

        table.insert(new_text, { "| " .. title, hlgroup })
        if #level > 0 then
            table.insert(new_text, { utils.format_raised(level), "Number" })
        end
    else -- otherwise keep the treesitter highlighting
        local target_width = width - suffix_width
        local cur_width = 0

        for _, chunk in ipairs(virt_text) do
            local text = chunk[1]
            local text_width = vim.fn.strdisplaywidth(text)
            if target_width > cur_width + text_width then
                table.insert(new_text, chunk)
            else
                text = truncate(text, target_width - cur_width)
                table.insert(new_text, { text, chunk[2] })
                break
            end
            cur_width = cur_width + text_width
        end
    end

    table.insert(new_text, { " ", "" })
    vim.list_extend(new_text, suffix)
    return new_text
end

---@type UfoConfig
local opts = {
    open_fold_hl_timeout = 0,
    fold_virt_text_handler = fold_formatter,
    close_fold_kinds_for_ft = {
        default = { "imports", "marker" },
        ---@diagnostic disable-next-line: assign-type-mismatch Treesitter node names can be used too
        c = { "preproc_include", "marker" },
        ---@diagnostic disable-next-line: assign-type-mismatch
        org = { "directive", "marker" },
    },
    provider_selector = function(bufnr, ft, bft)
        if ft == "qf" then
            return ""
        else
            return { merged_provider { "treesitter", "marker", "indent" }, "indent" }
        end
    end,
    preview = {
        win_config = {
            winblend = 0,
        },
        mappings = {
            switch = "<space>z"
        }
    },
}

M.config = function()
    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    ufo = require("ufo")
    ufo.setup(opts)

    utils.map("n", "zM", ufo.closeAllFolds)
    utils.map("n", "zR", ufo.openAllFolds)
    utils.map("n", "zm", function() ufo.closeFoldsWith(vim.v.count1) end)

    -- HACK: reset colorscheme
    vim.defer_fn(function()
        vim.cmd.colorscheme(vim.g.colors_name)
    end, 1000)
end

return M
