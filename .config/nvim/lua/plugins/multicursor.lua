---@type LazySpec
local M = {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
}

--[[ Information {{{
Multiple cursors for neovim:
I generally use them as a replacement for macros and complex :g commands

Leader Key: -

Ways to add cursors:
- motion: --<motion>
- search: /<search term><cr>-/
- word match (like *):
    - all: -*
    - in scope: -w<motion>
    - custom match in scope: -o<motion><motion>
- splitting / matching a visual selection:
    - split: -s<regex><cr>
    - match: -m<regex><cr>

Actions to perform on cursors:
- Perform *completely normal* vim edits
- Each cursor has its own undo, registers &c
- Align the text after/on cursors: -A
}}} --]]

---@param ctx mc.CursorContext
---@param capture string
---@param range [integer, integer, integer, integer]
local cursor_for_ts_node = function(ctx, capture, range)
    local main = ctx:mainCursor()

    local matches = require("config.lib.query").get_matches_in_range(0, "textobjects", capture, range, false)

    if not matches then
        return
    end

    for _, node in pairs(matches) do
        local srow, scol, erow, ecol = vim.treesitter.get_node_range(node)
        main:clone():setMode("v"):setVisual({ erow + 1, ecol }, { srow + 1, scol + 1 })
    end

    main:delete()
end

local map_select_operator = function(keys, capture, desc)
    require("config.lib.operators").map_function(keys, function(mode, region)
        local endline = region[2][1]
        require("multicursor-nvim").action(function(ctx)
            cursor_for_ts_node(ctx, capture, {
                region[1][1] - 1,
                region[1][2],
                endline - 1,
                mode == "line" and #vim.api.nvim_buf_get_lines(0, endline - 1, endline, false)[1] or
                region[2][2]
            })
        end)
    end, { desc = desc })
end

function M.config()
    local mc = require("multicursor-nvim")
    mc.setup()

    local utils = require("config.utils")
    local map = utils.map
    local action = utils.mode_action
    local operators = require("config.lib.operators")

    map("n", "<esc>", function()
        if mc.hasCursors() then
            mc.clearCursors()
            vim.api.nvim_exec_autocmds("ModeChanged", {})
        end

        if vim.snippet.active() then
            vim.snippet.stop()
        end
    end)

    map("n", "-", "<nop>")

    map(action, "-x", mc.deleteCursor, { desc = "Cursor: Delete current" })
    map(action, "-u", mc.restoreCursors, { desc = "Cursor: Undo clear" })
    map(action, "-j", mc.nextCursor, { desc = "Cursor: Next below" })
    map(action, "-k", mc.prevCursor, { desc = "Cursor: Next above" })
    map(action, "-$", mc.lastCursor, { desc = "Cursor: Last" })
    map(action, "-0", mc.firstCursor, { desc = "Cursor: First" })

    -- Creating new cursors {{{
    map(action, "-n", function() mc.matchAddCursor(1) end, { desc = "Cursor: New on next *" })
    map(action, "-p", function() mc.matchAddCursor(-1) end, { desc = "Cursor: New on prev *" })
    map(action, "-*", mc.matchAllAddCursors, { desc = "Cursor: New on all *" })

    -- turns multiple cursors into another vim command more than a full mode
    -- for linewise mode or when spanning multiple lines: create one cursor for each line, at the same position as the original one
    -- for charwise mode on a single line: create a single cursor at the destination of the motion
    operators.map_function("--", function(mode, region, extra)
        if mode == "line" or region[2][1] ~= region[1][1] then
            local original_column = vim.fn.charcol(".")
            mc.action(function(ctx)
                for i = region[1][1] + 1, region[2][1] do
                    local cursor = ctx:addCursor()
                    cursor:setPos({ i, original_column })
                    cursor:feedkeys(original_column .. "|")
                end
            end)
        elseif mode == "char" then
            mc.action(function(ctx)
                local main = ctx:mainCursor()
                main:clone()
                main:setPos({ region[2][1], region[2][2] + 1 })
            end)
        end
    end, { normal_only = true, no_repeated = true, desc = "Cursor: New for motion" })

    map("x", "--", mc.visualToCursors, { desc = "Cursor: On each line" })
    -- put one cursor at each current search result
    map("n", "-/", mc.searchAllAddCursors, { desc = "Cursor: New for /" })

    -- align cursors: all to same column
    map(action, "-|", function()
        mc.action(function(ctx)
            local maincol = vim.fn.charcol(".")
            ctx:forEachCursor(function(cursor)
                if not cursor:isMainCursor() then
                    cursor:feedkeys(maincol .. "|")
                end
            end)
        end)
    end, { desc = "Cursor: Align column" })

    -- really useful with syntactically aware textobjects:
    -- `-wif` puts a cursor on every match in a function
    -- `-wi<space>` in lua does the same for a block
    -- this can be a real alternative to the lsp based one
    map(action, "-w", function()
        ---@diagnostic disable-next-line: missing-fields
        mc.operator { motion = "iw", visual = true }
    end, { desc = "Cursor: New for word in" })

    -- allows for things that are more than one <word>, e.g. i.
    map(action, "-o", mc.operator, { desc = "Cursor: New for obj in" })

    -- treesitter aware, put a cursor on each capture with the field that is *fully* inside the motion:
    -- -a_ to match all function arguments on the current line
    -- -aiF to match all arguments to a function call
    map_select_operator("-a", "parameter.inner", "Cursor: Select arguments")

    -- a cursor on/selecting each reference of the symbol under the cursor
    require("config.lsp").lsp_map("n", "-r", function()
        local fname = vim.api.nvim_buf_get_name(0)
        vim.lsp.buf.references(nil, {
            on_list = function(res)
                mc.action(function(ctx)
                    local main = ctx:mainCursor()
                    for _, item in ipairs(res.items) do
                        if item.filename == fname then
                            main:clone():setMode("v"):setVisual({ item.end_lnum, item.end_col - 1 },
                                { item.lnum, item.col })
                        end
                    end
                    main:delete()
                end)
            end
        })
    end, { desc = "Cursor: Select references" })

    map("n", "-s", function()
        require("leap").leap {
            target_windows = { 0 },
            action = function(args)
                mc.action(function(ctx)
                    ctx:addCursor():setPos(args.pos)
                end)
            end
        }
    end, { desc = "Cursor: New for leap" })
    -- }}}

    -- Visual Selections {{{
    map("x", "-s", mc.splitCursors, { desc = "Cursor: Split visual" })
    map("x", "-m", mc.matchCursors, { desc = "Cursor: Match visual" })

    map("x", "-?", function()
        local filter = vim.fn.input {
            prompt = "Regex: ",
        }

        local inverse = false
        if filter:sub(1, 1) == "!" then
            inverse = true
            filter = filter:sub(2)
        end

        local re = vim.regex(filter)

        mc.action(function(ctx)
            ctx:forEachCursor(function(cursor)
                local selection = table.concat(cursor:getVisualLines(), "\n")
                local matches = re:match_str(selection) ~= nil
                if (inverse and matches) or (not inverse and not matches) then
                    cursor:delete()
                end
            end)
        end)
    end, { desc = "Cursor: Filter by regex" })

    map("x", "->", function() mc.transposeCursors(1) end, { desc = "Cursor: Rotate forwards" })
    map("x", "-<", function() mc.transposeCursors(-1) end, { desc = "Cursor: Rotate backwards" })
    map("x", "-l", function() mc.swapCursors(1) end, { desc = "Cursor: Swap forwards" })
    map("x", "-h", function() mc.swapCursors(-1) end, { desc = "Cursor: Swap backwards" })
    map(action, "-A", mc.alignCursors, { desc = "Cursor: Align content" })
    -- }}}

    -- replace default I and A for visual mode
    map("x", "I", mc.insertVisual)
    map("x", "A", mc.appendVisual)

    mc.addKeymapLayer(function(set)
        set("n", "-i", function()
            mc.action(function(ctx)
                ctx:forEachCursor(function(cursor, i)
                    cursor:feedkeys(("i%d\x1b"):format(i), {
                        remap = false
                    })
                end)
            end)
        end, { desc = "Cursor: Insert index" })
    end)
end

return M
