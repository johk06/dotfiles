--[[ Synopsis: Custom Motions and Improvements on Builtins {{{
 Textobjects and motions are the heart of Vim, so it makes sense to optimize
 them more than almost everything else. This file has both abbreviations
 for, as well as new, motions and textobjects (mostly).
]]

local fn = vim.fn
local utils = require("config.utils")
local map = utils.map
local mov = utils.mode_motion
local obj = utils.mode_object
local textobjs = require("config.lib.textobjs")
local operators = require("config.lib.operators")
-- }}}

-- Center the screen for jumps
map(mov, "<C-o>", "<C-o>zz")
map(mov, "<C-i>", "<C-i>zz")

--[[ Start and End of Line {{{
 These are hard to reach by default,
 I do not use Low and High for navigation and even rarer in o-pending mode
 also kinda logical, like a stronger version of lh
]]
map(mov, "L", "$")
-- 0 is significantly less useful than ^ and easier to reach as well
map(mov, "H", "^")

-- Keep the old ones around though, mostly out of habit
map(mov, "gL", "L")
map(mov, "gH", "H")

-- Find in the line from the back, remap=true for lua/plugins/blinkenfind.lua to kick in
map(mov, "<M-f>", "$F", { remap = true })
map(mov, "<M-t>", "$T", { remap = true })
-- }}}

-- Keep the jumplist intact for {}, it's a relatively small motion
map(mov, "{", function() return "<cmd>keepj normal!" .. vim.v.count1 .. "{<cr>" end, { remap = false, expr = true })
map(mov, "}", function() return "<cmd>keepj normal!" .. vim.v.count1 .. "}<cr>" end, { remap = false, expr = true })

--[[ Tweaks to * and # {{{
 These are quite useful, but occasionally surprise with annoying behavior
]]
-- Allow the selection of * and # to be via a textobject, this obsoletes v<motion>* for me
-- TODO: evaluate

local after_star_op
local star_operator = function(forward)
    return function(mode, region, _)
        local text = table.concat(operators.get_region(mode, region), "\n")
        fn.setreg("/", "\\V" .. text:gsub("\\", "\\\\"):gsub("/", "\\/"))
        vim.v.searchforward = forward
        vim.cmd.normal { "n", bang = true }

        if after_star_op then
            after_star_op()
        end
        after_star_op = nil
    end
end
operators.map_function("z*", star_operator(1))
operators.map_function("z#", star_operator(0))

--[[ turn the *Ncgn pattern into a nice and small textobject
 Operators that don't invalidate the match require `n` afterwards to move the cursor.
 So anything that deletes, changes etc is best.
 Then continue hitting `.` to apply or `n` to go to the next match.
 This way this can work almost like :%s///c, but for arbitrary operations
 Examples:
 - gs* to replace each occurrence with register. ]]
map("o", "*", function() return "\x1b*N" .. vim.v.operator .. "gn" end, { expr = true })
map("o", "#", function() return "\x1b#N" .. vim.v.operator .. "gN" end, { expr = true })

-- And the same thing with another textobject for range
local star_parameter = function(forward, op)
    return function()
        local operator = vim.v.operator
        local opfunc = vim.o.operatorfunc
        after_star_op = function()
            vim.o.operatorfunc = opfunc
            vim.api.nvim_feedkeys(("N%sg%s"):format(operator, forward and "n" or "N"), "")
        end
        return ("<Esc>%s"):format(op)
    end
end

map("o", "z*", star_parameter(true, "z*"), { expr = true, remap = true })
map("o", "z#", star_parameter(false, "z#"), { expr = true, remap = true })

-- }}}
-- Delimiters {{{
-- % is annoying to press
-- [m]atching, this may take some inspiration from helix :)
map(obj, "m", "<plug>(matchup-%)")
map(obj, "im", "<plug>(matchup-i%)")
map(obj, "am", "<plug>(matchup-a%)")

-- less annoying to type
map(obj, "iq", [[i"]])
map(obj, "aq", [[a"]])
map(obj, "iQ", [[i']])
map(obj, "aQ", [[a']])
-- }}}
--[[ Diagnostics {{{
 Examples:
 - cid_<esc> to change an "unused variable" ]]
map(obj, "id", textobjs.diagnostic)
map(obj, "iDe", textobjs.diagnostic_error)
map(obj, "iDw", textobjs.diagnostic_warn)
map(obj, "iDi", textobjs.diagnostic_info)
map(obj, "iDh", textobjs.diagnostic_hint)
-- }}}
--[[ Indents {{{
 Very useful for python or other indent based languages:
 `a` includes one line above and below, except for filetypes like python or
     lisps where only the above line is included by default.
 `aI` always includes the line below too, even for python et cetera, useful for
     object literals like dicts or lists or nested languages

 If present, v:count specifies the amount of indent levels instead of the current cursor position
 this is particularly useful for languages like python where
 c1ii comes to mean "change in the topmost scope"
 d2ai for example then means "delete this method"
 NOTE: this uses shiftwidth, so it's not 100% reliable for files that do not
 have the same shiftwidth or variations in its indent width, furthermore there
 are issues with e.g. labels in C which come in the first column by convention ]]
map(obj, "ii", textobjs.indent_inner)
map(obj, "ai", textobjs.indent_outer)
map(obj, "aI", textobjs.indent_outer_with_last)
-- }}}

-- Foldmarker section - *not* a fold
map(obj, "iz", textobjs.foldmarker_inner)
map(obj, "az", textobjs.foldmarker_outer)

-- snake_case or kebab-case sub-word
map(obj, "i-", textobjs.create_pattern_obj("([-_]?)%w+([-_]?)"))
map(obj, "a-", textobjs.create_pattern_obj("()[-_]?%w+[-_]?()"))

-- Object chain, most languages, NOTE: does not include lua `:`
-- This can also be taken as a generic identifier object
-- For languages that do not include e.g. -
map(obj, "i.", textobjs.create_pattern_obj("()[%w._]+()"))
map(obj, "a.", textobjs.create_pattern_obj("()%s*[%w._]+%s*()"))

-- Path component, last / is optional
map(obj, "i/", textobjs.create_pattern_obj("(/)[^/]+(/?)"))
map(obj, "a/", textobjs.create_pattern_obj("/()[^/]+()/?"))

--[[ Numbers
 Inner variant preserves the sign of the number as well as any potential type prefix (0x) etc ]]
map(obj, "in", textobjs.create_pattern_obj {
    "([+-]?0x)%x+()",    -- decimal int
    "([+-]?0b)[01]+()",  -- binary int
    "([+-]?0o)[0-7]+()", -- octal int
    "([+-]?)%d+%.%d*()", -- decimal float
    "([+-]?)%d+()",      -- decimal int
})
map(obj, "an", textobjs.create_pattern_obj {
    "()[+-]?0x%x+()",    -- decimal int
    "()[+-]?0b[01]+()",  -- binary int
    "()[+-]?0o[0-7]+()", -- octal int
    "()[+-]?%d+%.%d*()", -- decimal float
    "()[+-]?%d+()",      -- decimal int
})

-- Entire buffer, mirroring the motions that would achieve the same thing: VgG
map(obj, "gG", textobjs.entire_buffer)

-- C-style variable value; ignore visual mode since = is useful there
-- this is a heuristic, for "proper variable" declarations use `iv` from treesitter
map("o", "=", textobjs.variable_value)

--[[ focus the current fold
 - zM: close all folds
 - zv: open enough folds so the current line is visible
 - [z: move to the top of it
 - zt: place it at the top of the screen
 the j is required so that this applies when on the fold start ]]
map("n", "<Tab>", "zMzv[zjzt", { remap = true --[[ is required so ufo applies ]] })

-- Move between snippet fields
map({ "n", "s", "i" }, "<M-space>", function() vim.snippet.jump(1) end)
map({ "n", "s", "i" }, "<C-space>", function() vim.snippet.jump(-1) end)
