--[[ Synopsis: Custom Operators {{{
 Operators are an incredibly important part of vim
 This file mostly has operators where no plugin has managed to satisfy me (yet)
]]

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local map = utils.map
local operators = require("config.lib.operators")
-- }}}

--[[ Command in Region
 Open a cmdline in a region specified by a textobject or motion
 Allows repeating commands like they're regular mappings
 mostly useful with things like :g, :s and :! ]]
---@type config.op.operator_func
local command_in_region = function(_, region, extra)
    local start_line = region[1][1]
    local end_line = region[2][1]

    if extra.repeated then
        local cmd = string.format("%d,%d%s", start_line, end_line, extra.saved.cmd)

        ---@diagnostic disable-next-line: param-type-mismatch
        local ok, err = pcall(vim.cmd, cmd)
        if not ok and err then
            vim.notify(tostring(err), vim.log.levels.ERROR)
        end
    else
        local cmd_with_range = string.format(":%d,%d", start_line, end_line)
        api.nvim_feedkeys(cmd_with_range, "n", false)

        api.nvim_create_autocmd("CmdlineLeave", {
            once = true,
            callback = function()
                local command_line = fn.getcmdline()
                local command = command_line:match("^%d+,%d+(.*)$")
                if not command then
                    command = ""
                end
                extra.saved.cmd = command
            end
        })
    end
end
operators.map_function("g:", command_in_region)

---@param lines string[]
---@param count integer
---@return string[]
local multiply_lines = function(lines, count)
    local ret = {}
    if count <= 1 then
        return lines
    end
    for _ = 1, count do
        vim.list_extend(ret, lines)
    end

    return ret
end

--[[ Duplicate elements
 [g]o [m]ultiply
 uses the first count as an indication of how often to multiply
 e.g. 2gmiw -> duplicates the current word twice
 If the object to multiply is an inline word and does not have a separator,
 a space will be added.
 The capital version puts the duplicate before the cursor instead of after it.
 Examples:
 - gmaa to duplicate an argument to a function, e.g. type `, NULL` once and then gmaa it
 - gmm followed by an edit to create a slightly different copy of the current line

 As many commentators correctly pointed out, yyp not leaving the cursor in
 place makes this more difficult with builtins
 This new operator has the added benefit of leaving all the registers alone ]]
---@type config.op.operator_func
local multiply_operator = function(mode, region, extra)
    local before = extra.args and extra.args.before or false
    local target = before and { region[1], region[2] } or { region[3], region[4] }

    if mode == "char" and region[1] == region[3] then
        local text = operators.get_region(mode, region)
        local sel = text[1]
        if not (sel:match("%s$") or sel:match("^%s") or sel:match("%W$") or sel:match("^%W")) then
            if before then
                sel = sel .. " "
            else
                sel = " " .. sel
            end
        end
        local to_insert = { sel:rep(math.max(1, extra.hijacked_count)) }

        local row = target[1] - 1
        local col = target[2] + (before and 0 or 1)
        api.nvim_buf_set_text(0, row, col, row, col, to_insert)
    else
        local text = operators.get_region("line", region)
        local to_insert = multiply_lines(text, extra.hijacked_count)
        local line = before and target[1] - 1 or target[1]
        api.nvim_buf_set_lines(0, line, line, false, to_insert)
    end
end
operators.map_function("gm", multiply_operator, { hijack_count = true })
operators.map_function("gM", multiply_operator, { hijack_count = true }, { before = true })

--[[ Sort a range of lines/elements
 In a single line: use commas
 Otherwise: sort lines
 Anything that this can't do should be done with :!sort anyways ]]
operators.map_function("g=", function(mode, region, _)
    local text = operators.get_region(mode, region)
    local items
    local comma_separated = #text == 1
    if comma_separated then
        items = vim.split(text[1], ",")
    else
        items = text
    end

    local whites = {}
    local texts = {}
    for _, item in ipairs(items) do
        local leading_white = item:match("^(%s*)")
        local trailing_white = item:match("(%s*)$")
        table.insert(whites, { leading_white, trailing_white })
        table.insert(texts, vim.trim(item))
    end

    table.sort(texts)

    local replacements = {}
    for i, white in ipairs(whites) do
        table.insert(replacements,
            white[1] .. texts[i] .. white[2]
        )
    end

    if comma_separated then
        operators.set_region("char", region, { table.concat(replacements, ",") })
    else
        operators.set_region(mode, region, replacements)
    end
end)

-- like (now-default) []<space>, but for characters inside a line, e.g. to separate words
local insert_spaces = function(direction)
    local spaces = (" "):rep(vim.v.count1)
    local cursor = api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = direction < 0 and cursor[2] or cursor[2] + 1
    api.nvim_buf_set_text(0, row, col, row, col, { spaces })

    return "g@l"
end
operators.map_repeatable("<<space>", function()
    insert_spaces(-1)
end)
operators.map_repeatable("><space>", function()
    insert_spaces(1)
end)

--[[ Transposing {{{
 Swap two regions based on three motions
]]
local range = vim.treesitter._range
local last_transpose
local transpose_range_1
local next_transpose_phase
local transpose_phase_2 = operators.make_operator("jhk-transpose-2", function(mode, region)
    local r1 = transpose_range_1
    local r2 = region
    if range.intercepts(r1, r2) then
        utils.error("Transpose", "Ranges cannot intersect")
        return
    end

    if range.cmp_pos.gt(r1[1], r1[2], r2[1], r2[2]) then
        r1, r2 = r2, r1
    end

    local sl2, sc2, el2, ec2 = r2[1] - 1, r2[2], r2[3] - 1, r2[4] + 1
    local sl1, sc1, el1, ec1 = r1[1] - 1, r1[2], r1[3] - 1, r1[4] + 1

    local t2 = api.nvim_buf_get_text(0, sl2, sc2, el2, ec2, {})
    local t1 = api.nvim_buf_get_text(0, sl1, sc1, el1, ec1, {})

    api.nvim_buf_set_text(0, sl2, sc2, el2, ec2, t1)
    api.nvim_buf_set_text(0, sl1, sc1, el1, ec1, t2)

    operators.Ctx.last = last_transpose

    last_transpose = nil
    transpose_range_1 = nil
    next_transpose_phase = nil
end, {}, false)

local transpose_phase_1 = operators.make_operator("jhk-transpose-1", function(mode, region)
    transpose_range_1 = region
    local next_step = next_transpose_phase[1]
    if type(next_step) == "function" then
        next_step()
    else
        api.nvim_feedkeys(next_step, "")
        api.nvim_feedkeys(transpose_phase_2() .. next_transpose_phase[2], "")
    end
end, {}, false)

local transpose_by_motion = function(keys, left, tfer, right)
    next_transpose_phase = { tfer, right }
    last_transpose = keys
    return transpose_phase_1() .. left
end

local map_transpose = function(keys, left, mid, right)
    operators.map_repeatable(keys, function()
        api.nvim_feedkeys(transpose_by_motion(keys, left, mid, right), "")
    end)
end

map_transpose("yxw", "iw", "W", "iw")
map_transpose("yxW", "iW", "W", "iW")
map_transpose("yxb", "iw", "B", "iw")
map_transpose("yxB", "iW", "B", "iW")
map_transpose("yx)", "a)", "f(", "a)")
map_transpose("yx(", "a)", "F)", "a)")
map_transpose("yx}", "a}", "f(", "a}")
map_transpose("yx{", "a}", "F}", "a}")
map_transpose(">x", "", function()
    api.nvim_create_autocmd("CursorMoved", {
        once = true,
        callback = function()
            api.nvim_feedkeys(transpose_phase_2(), "")
        end
    })
end)
-- }}}
