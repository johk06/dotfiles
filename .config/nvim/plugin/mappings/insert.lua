--[[ Synopsis: Improvements to Insert (and Command) Mode {{{
 Alternatively: a short list of heresies

 Leftover keys looking for a mapping:
 - <C-m> maybe, may conflict with <cr>
 - Leave M-* alone, a lot more useful for normal mode
]]

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local map = utils.map
local abbrev = utils.abbrev
-- }}}

--[[ Why would I want to do smth so un-vimmy?
 Well, on my keyboard tapping L/R Shift yields BS/Del,
 so tapping one shift key while holding the other makes sense ]]
map("i", "<S-BS>", "<C-w>")
map("i", "<S-Del>", "<c-o>\"_dw")

-- Go to basically any character in the line in insert mode
-- Navigation further than that needs normal mode anyways
map("i", "<C-f>", "<C-o>f", { remap = true })
map("i", "<C-b>", "<C-o>T", { remap = true })

-- Quick way to trigger things like ]a in insert mode
-- useful example: <C-.>a to go to the next argument
map("i", "<C-.>", "<C-o>]", { remap = true })
map("i", "<C-,>", "<C-o>[", { remap = true })
map("i", "<C-.><C-.>", "<C-o>;", { remap = true })
map("i", "<C-,><C-,>", "<C-o>,", { remap = true })

---@param char string
local toggle_char_at_eol = function(char)
    local line = api.nvim_get_current_line()
    local old_char = line:match("(" .. vim.pesc(char) .. "*)$")
    local lnum = api.nvim_win_get_cursor(0)[1]
    api.nvim_buf_set_text(0, lnum - 1, #line - #old_char, lnum - 1, #line, {
        #old_char == 0 and char or ""
    })

    return false
end

local map_eol_toggle = function(char)
    map("i", ("<M-%s>"):format(char), function() toggle_char_at_eol(char) end)
end

-- Most standard delimiters + escaping
map_eol_toggle ","
map_eol_toggle ";"
map_eol_toggle "\\"

-- Jump to previous spelling error and attempt to fix it
-- remap needed for telescope to kick in
map("i", "<C-z>", "<Esc>[sz=", { remap = true })

-- Exit terminal mode with a single chord instead of 2
map("t", "<M-Esc>", "<C-\\><C-n>")
map("t", "<M-C-w>", "<C-\\><C-n><C-w>")

-- Similar to how AI operate on lines
map("n", "<M-a>", "ea")
map("n", "<M-i>", "bi")

-- Command Mode {{{
-- I probably never will actually use :file
-- If I need it, i can survive typing the full name
local abbr_not_search = function(from, to)
    return from, function()
        local md = vim.fn.getcmdtype() == ":"
        if md then
            return to
        else
            return from
        end
    end, { expr = true }
end
map("ca", abbr_not_search("f", "find"))
map("ca", abbr_not_search("vf", "vertical sf")) -- much shorter, much more useful
-- Likewise, often useful for one-off commands
map("ca", abbr_not_search("vt", "vertical terminal"))
map("ca", abbr_not_search("st", "horizontal terminal"))

--[[ All of these are just shortcuts for simple text insertions for now
Some highlights:
- Fast inserting of common pattern characters in search mode ]]
---@param keys string
---@param rhs string|function
---@param desc string?
local map_search = function(keys, rhs, desc)
    map("c", keys, function()
        local cmdtype = fn.getcmdtype()
        local cmdline = fn.getcmdline()
        if cmdtype == "/" or cmdtype == "?"
            or cmdline:match("^%A*[sgv]") then
            if type(rhs) == "function" then
                return rhs()
            else
                return rhs
            end
        else
            return keys
        end
    end, { expr = true, desc = desc })
end

map_search("<M-space>", "\\s*", "Search: Any Whitespace")
map_search("<C-space>", "\\s\\+", "Search: Some Whitespace")
map_search("<M-s>", ".\\{-\\}", "Search: Anything")

map_search("<M-d>", function()
    return ("\\%%(%s\\)"):format(vim.o.define)
end, "Search: Definition")
map_search("<M-i>", function()
    return vim.o.include
end, "Search: Include")

map_search("<M-k>", "\\<\\><Left><Left>", "Search: Keyword")
map_search("<M-g>", "\\(\\)<Left><Left>", "Search: Group")

-- Move to next part of :s
map_search("<M-/>", function()
    local cmdline = fn.getcmdline()
    local replaced = cmdline:gsub("/*$", "/")
    fn.setcmdline(replaced, #replaced + 1)
end)
-- }}}
