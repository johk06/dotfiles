local M = {}
local api = vim.api
local esc = api.nvim_replace_termcodes("<esc>", true, false, true)
local ftpref = require("config.lib.ftpref")
local utils = require("config.utils")

local MAX_LINES_FORWARD = 20

--[[ Information {{{
see https://github.com/chrisgrieser/nvim-various-textobjs

This will be nowhere near as complex, I just want a framework for my own
see ./operators.lua as well

Important ones:
 - indent: ii, ai, aI
 - diagnostics: id, iDe, iDw, iDi, iDh
 - arbitrary single-line regexes
 - entire buffer: gG
 - variable value: =
 - arbitrary treesitter node: .
}}} ]]
-- Infrastructure {{{
---@alias seltype "line"|"char"
---@alias textobject fun(pos: Range2|Range4, lcount: integer, opts: any?): ((Range2|Range4)?, seltype?)

---@param cmdstr string
local function norm(cmdstr)
    vim.cmd.normal { cmdstr, bang = true }
end

local function cancel_selection()
    if api.nvim_get_mode().mode == "no" then
        api.nvim_feedkeys(esc, "n", false)
    end
end

local function getline(lnum)
    return api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
end

---@param sel Range2 | Range4 Either a point or a region
local set_selection = function(mode, sel)
    norm("m`")
    ---@cast mode seltype
    if #sel == 2 then -- motion
        ---@cast sel Range2
        api.nvim_win_set_cursor(0, sel)
    else -- textobject
        local vimode = api.nvim_get_mode().mode
        api.nvim_win_set_cursor(0, { sel[1], sel[2] })

        local isvisreg = vimode:find("v")
        local isvisline = vimode:find("V")
        local isvis = isvisreg or isvisline
        local linewise = mode == "line"

        if isvisreg and linewise then
            norm("V")
        end

        if isvis then
            norm("o")
        else
            if linewise then norm("V") else norm("v") end
        end

        api.nvim_win_set_cursor(0, { sel[3], sel[4] })
    end
end

---@param fn textobject
---@param opts table<string, any>
function M.create_textobj(fn, opts)
    return function()
        local curpos = api.nvim_win_get_cursor(0)
        if api.nvim_get_mode().mode == "v" then
            local vis = vim.fn.getpos("v")
            local cur =  vim.fn.getpos(".")
            if vis[2] > cur[2] or (vis[2] == cur[2] and vis[3] > cur[3]) then
                vis, cur = cur, vis
            end
            curpos = {
                vis[2], vis[3],
                cur[2], cur[3]
            }
        end
        local lcount = api.nvim_buf_line_count(0)
        local sel, mode = fn(curpos, lcount, opts)
        if (not sel) or (not mode) then
            cancel_selection()
            return
        end

        set_selection(mode, sel)
    end
end

-- }}}

-- Diagnostics {{{
---@type textobject
local function diagnostic(pos, lcount, opts)
    local args = {
        wrap = false,
        cursor_position = pos,
    }

    local prev_diag = vim.diagnostic.get_prev(args)
    local on_prev = false
    local next_diag = vim.diagnostic.get_next(args)

    if prev_diag then
        local cur_after_prev_start = (pos[1] == prev_diag.lnum + 1 and pos[2] >= prev_diag.col) or
            (pos[1] > prev_diag.lnum + 1)

        local cur_befor_prev_end = (pos[1] == prev_diag.end_lnum + 1 and pos[1] <= prev_diag.end_col - 1) or
            (pos[1] < prev_diag.end_lnum)

        on_prev = cur_after_prev_start and cur_befor_prev_end
    end

    local target = on_prev and prev_diag or next_diag

    if target then
        if opts.type then
            local diagtype = target.severity
            if diagtype ~= opts.type then
                return diagnostic({ target.end_lnum + 2, target.end_col + 2 }, lcount, opts)
            end
        end
        return { target.lnum + 1, target.col, target.end_lnum + 1, target.end_col - 1 }, "char"
    end

    return nil, nil
end

M.diagnostic = M.create_textobj(diagnostic, { type = nil })
M.diagnostic_error = M.create_textobj(diagnostic, { type = vim.diagnostic.severity.ERROR })
M.diagnostic_warn = M.create_textobj(diagnostic, { type = vim.diagnostic.severity.WARN })
M.diagnostic_info = M.create_textobj(diagnostic, { type = vim.diagnostic.severity.INFO })
M.diagnostic_hint = M.create_textobj(diagnostic, { type = vim.diagnostic.severity.HINT })
-- }}}
-- Indent {{{
local function line_is_blank(lnum)
    local line = getline(lnum)
    return line:find("^%s*$") ~= nil
end

local function indent(pos, lcount, opts)
    local curl = pos[1]

    while (line_is_blank(curl)) do
        if curl == lcount then
            return
        end
        curl = curl + 1
    end

    local start_indent
    if vim.v.count > 0 then
        start_indent = vim.v.count * vim.bo[0].shiftwidth
    else
        start_indent = vim.fn.indent(curl)
    end
    if start_indent == 0 then
        return
    end

    local prevl = curl - 1
    local nextl = curl + 1

    while prevl > 0 and (line_is_blank(prevl) or vim.fn.indent(prevl) >= start_indent) do
        prevl = prevl - 1
    end

    while nextl <= lcount and (line_is_blank(nextl) or vim.fn.indent(nextl) >= start_indent) do
        nextl = nextl + 1
    end

    if opts.outer and not opts.always_last and ftpref[vim.bo[0].ft].indent_only_above then
        nextl = nextl - 1
    end
    if not opts.outer then
        prevl = prevl + 1
        nextl = nextl - 1
    end

    if nextl > lcount then
        nextl = lcount
    end

    while line_is_blank(nextl) do
        nextl = nextl - 1
    end

    return { prevl, 1, nextl, 1 }, "line"
end

M.indent_inner = M.create_textobj(indent, { outer = false })
M.indent_outer = M.create_textobj(indent, { outer = true })
M.indent_outer_with_last = M.create_textobj(indent, { outer = true, always_last = true })
-- }}}
-- Variable assignments {{{
-- Very coarse variable assigned value logic
M.variable_value = M.create_textobj(function(pos, lcount, opts)
    local lnum = pos[1]
    local line = getline(lnum)

    local eq_pos = line:find("=")
    if not eq_pos then
        return
    end

    local _, _, prefix = line:find("(%s*).*", eq_pos + 1)
    local eq_value_pos = eq_pos + #prefix

    -- try to avoid common suffixes
    local trailing_sep = line:match("([,;]%s*)$")
    return { lnum, eq_value_pos, lnum, #line - (trailing_sep and #trailing_sep + 1 or 1) }, "char"
end, {})
-- }}}
-- Patterns {{{
local find_any = function(text, patterns, startpos)
    for _, pattern in ipairs(patterns) do
        local start, stop, g1, g2 = text:find(pattern, startpos)
        if start then
            return start, stop, g1, g2
        end
    end
end
-- search for a pattern, use capture group to specify what to match
-- two capture groups are necessary: an optional prefix and suffix
-- if you don't need prefix and suffix, use ()
local function pattern_obj(pos, lcount, opts)
    local curline = pos[1]
    local curcol = pos[2]
    local patterns = type(opts.patterns) == "string" and { opts.patterns } or opts.patterns

    local line = getline(curline)

    local startpos = 0 ---@type integer?
    local endpos

    local g1, g2

    repeat
        startpos = startpos + 1
        startpos, endpos, g1, g2 = find_any(line, patterns, startpos)
    until not startpos or (endpos and endpos > curcol)

    local count = 1
    -- not found in first line
    if not startpos then
        while count < MAX_LINES_FORWARD do
            if curline > lcount then
                return
            end
            curline = curline + 1
            line = getline(curline)
            startpos, endpos, g1, g2 = find_any(line, patterns)
            if startpos then
                break
            end
            count = count + 1
        end
    end

    if not startpos then
        return
    end

    local obj_start = (type(g1) ~= "number" and #g1 or 0) + startpos
    local obj_end = endpos - (type(g2) ~= "number" and #g2 or 0)
    return { curline, obj_start - 1, curline, obj_end - 1 }, "char"
end

function M.create_pattern_obj(patterns)
    return M.create_textobj(pattern_obj, { patterns = patterns })
end

-- }}}
-- Treesitter {{{
local ts = vim.treesitter

---@type textobject
---@param opts {transform: fun(node: TSNode): TSNode?}
local ts_object = function(pos, lcount, opts)
    local parser, err = ts.get_parser(0)
    if not parser then
        return utils.error("Treesitter", err or "")
    end

    if #pos == 2 then
        vim.list_extend(pos, pos)
    end
    pos[1] = pos[1] - 1
    pos[3] = pos[3] - 1
    local node = parser:node_for_range(pos)
    if not node then
        return
    end
    node = opts.transform and opts.transform(node) or node

    local srow, scol, erow, ecol = ts.get_node_range(node)

    return { srow + 1, scol, erow + 1, ecol - 1 }, "char"
end

M.treesitter_node = M.create_textobj(ts_object, {})
M.treesitter_parent = M.create_textobj(ts_object, {
    ---@param node TSNode
    transform = function(node)
        return node:parent()
    end
})
M.treesitter_child = M.create_textobj(ts_object, {
    ---@param node TSNode
    transform = function(node)
        return node:child(vim.v.count)
    end
})
-- }}}
-- Miscellaneous {{{
local function foldmarker_object(pos, count, opts)
    local marker = vim.opt.foldmarker:get()

    local startpattern = vim.pesc(marker[1])
    local endpattern = vim.pesc(marker[2])
    local line = pos[1]
    local startline, endline
    local maxlines = vim.api.nvim_buf_line_count(0)

    startline = line
    local found_start_behind = true
    while not getline(startline):find(startpattern) do
        startline = startline - 1
        if startline <= 1 then
            found_start_behind = false
            break
        end
    end
    if not found_start_behind then
        startline = line
        while not getline(startline):find(startpattern) do
            startline = startline + 1
            if startline >= maxlines then
                return
            end
        end
    end


    endline = startline + 1
    while not getline(endline):find(endpattern) do
        endline = endline + 1
        if endline >= maxlines + 1 then
            return
        end
    end

    local ret = {
        startline + (opts.outer and 0 or 1), 0,
        endline - (opts.outer and 0 or 1), 0,
    }
    return ret, "line"
end

M.entire_buffer = M.create_textobj(function(_, lcount, _)
    return { 1, 0, lcount, 0 }, "line"
end, {})

M.foldmarker_outer = M.create_textobj(foldmarker_object, { outer = true })
M.foldmarker_inner = M.create_textobj(foldmarker_object, { outer = false })
-- }}}

return M
